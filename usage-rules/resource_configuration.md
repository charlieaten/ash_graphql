<!--
SPDX-FileCopyrightText: 2020 Zach Daniel

SPDX-License-Identifier: MIT
-->

# Resource Configuration

Each resource that you want to expose via GraphQL needs to include the AshGraphql.Resource extension.

## Setting Up Resources

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    extensions: [AshGraphql.Resource]

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :published, :boolean
    attribute :view_count, :integer
  end

  relationships do
    belongs_to :author, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
  end

  graphql do
    # The GraphQL type name (required)
    type :post

    # Explicit output fields. When present, this block is exclusive:
    # it replaces show_fields, hide_fields, relationships, field_names,
    # and nullable_fields.
    # Listed fields are exposed even if the underlying Ash field is not public.
    # Normal fields are nullable by default; identity fields default to non-null ID.
    fields do
      identity :id
      field :title
      field :summary, source: :computed_summary
    end

    # Customize attribute types for GraphQL
    attribute_types view_count: :string

    # Configure managed relationships (for nested create/update)
    managed_relationships do
      managed_relationship :with_comments, :comments
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list_published do
      filter expr(published == true)
    end

    update :publish do
      accept []
      change set_attribute(:published, true)
    end
  end
end
```
