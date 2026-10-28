require "spec_helper"
require "db-query-matchers"

RSpec.describe "Aggregates with scopes built from a model class" do
  before do
    allow(JitPreloader).to receive(:max_ids_per_query).and_return(nil)
    stub_const("ScopedCountry", Class.new(Country) do
      has_many :matching_contacts, -> { Contact.where(name: "Match") }, through: :addresses, source: :contact
      has_many_aggregate :matching_contacts, :count, :count, "*"
    end)
  end

  it "retains the through join when applying a class-based scope across owners" do
    countries = [Country.create!(name: "First"), Country.create!(name: "Empty")]
    ["Match", "Other"].each do |name|
      Address.create!(country: countries.first, contact: Contact.create!(name: name), street: "Test")
    end
    owners = ScopedCountry.where(id: countries.map(&:id)).order(:id).jit_preload.to_a

    expect do
      expect(owners.map(&:matching_contacts_count)).to eq([1, 0])
    end.to make_database_queries(count: 1)
  end
end
