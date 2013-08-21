class ProviderSerializer < ActiveModel::Serializer
  attributes :id, :name, :street, :city, :zip_code
  has_many :inpatient_charges
end
