# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Test.ExplicitFields do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshGraphql.Resource]

  graphql do
    type :explicit_fields
    encode_primary_key?(false)

    fields do
      identity :code, deprecate: "Use `id` instead."
      field :name, source: :resolved_name
      field :public_note, deprecate: true
    end

    queries do
      get :explicit_field, :read
      list :explicit_fields, :read
    end

    mutations do
      create :create_explicit_fields, :create
    end
  end

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:code, :internal_name, :secret, :public_note])
    end
  end

  attributes do
    attribute :code, :string do
      primary_key?(true)
      allow_nil?(false)
    end

    attribute :internal_name, :string do
      allow_nil?(false)
    end

    attribute :secret, :string do
      allow_nil?(false)
    end

    attribute :public_note, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  relationships do
    has_many :translations, AshGraphql.Test.ExplicitFieldTranslation do
      source_attribute(:code)
      destination_attribute(:explicit_field_code)
    end
  end

  calculations do
    calculate(:resolved_name, :string, expr(first(translations, field: :name) || internal_name))
  end
end
