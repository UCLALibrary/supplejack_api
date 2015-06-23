# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

class RecordSchema
  include SupplejackApi::SupplejackSchema

  # Namespaces
  namespace :dc, url: 'http://purl.org/dc/elements/1.1/'

  # Fields
  string    :record_id,    store: false
  string    :name,         search_boost: 10,      search_as: [:filter, :fulltext], namespace: :dc
  string    :address,      search_boost: 2,       search_as: [:filter, :fulltext]
  string    :email,        multi_value: true,     search_as: [:filter]
  string    :children,     multi_value: true
  string    :contact,      multi_value: true
  integer   :age
  datetime  :birth_date
  boolean   :nz_citizen,                          search_as: [:filter]

  # Groups
  group :default do
    fields [
      :name,
      :address
    ]
  end

  group :all do
    includes [:default]
    fields [
      :email,
      :children,
      :nz_citizen,
      :birth_date,
      :age
    ]
  end

  group :core do
    fields [:record_id]
  end

  group :sets do
    fields [
      :name,
      :address
    ]
  end

   # Roles
  role :developer, default: true
  role :admin, admin: true

end
