require "spec_helper"
require "db-query-matchers"

RSpec.describe "Aggregate caller conditions" do
  let!(:books) { Array.new(3) { ContactBook.create! } }

  before do
    allow(JitPreloader).to receive(:max_ids_per_query).and_return(nil)
    stub_const("ConditionsContactBook", Class.new(ContactBook) do
      has_many_aggregate :companies, :count, :count, "*"
      has_many_aggregate :companies, :count_with_max_ids_set, :count, "*", max_ids_per_query: 2
    end)
    Company.create!(contact_book: books.first, name: "Match")
    Company.create!(contact_book: books.first, name: "Other")
    Employee.create!(contact_book: books.first, name: "Match")
    Company.create!(contact_book: books.second, name: "Match")
  end

  it "preserves same-table filters and STI constraints across all owners without mutating the caller" do
    conditions = { "contacts" => { "name" => "Match" } }
    original_conditions = conditions.deep_dup
    owners = ConditionsContactBook.order(:id).jit_preload.to_a

    expect do
      expect(owners.map { |owner| owner.companies_count(conditions) }).to eq([1, 1, 0])
    end.to make_database_queries(count: 1)
    expect(conditions).to eq(original_conditions)

    expect do
      expect(owners.map { |owner| owner.companies_count("contacts" => { "name" => "Other" }) }).to eq([1, 0, 0])
    end.to make_database_queries(count: 1)

    expect do
      expect(owners.map { |owner| owner.companies_count(conditions) }).to eq([1, 1, 0])
    end.to_not make_database_queries
    expect(ContactBook.find(books.first.id).companies_count(conditions)).to eq(1)
  end

  it "preserves the caller filters when aggregating in slices" do
    owners = ConditionsContactBook.order(:id).jit_preload.to_a
    conditions = { "contacts" => { "name" => "Match" } }

    expect do
      expect(owners.map { |owner| owner.companies_count_with_max_ids_set(conditions) }).to eq([1, 1, 0])
    end.to make_database_queries(count: 2)
    expect(conditions).to eq("contacts" => { "name" => "Match" })
  end
end
