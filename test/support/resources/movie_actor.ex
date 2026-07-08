# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Test.MovieActor do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults([:update, :destroy, :read])

    create :create do
      primary?(true)
      accept([:movie_id, :actor_id, :position, :distance_meters])
    end
  end

  attributes do
    attribute(:position, :integer, public?: false)
    attribute(:distance_meters, :integer, public?: false)
  end

  relationships do
    belongs_to :movie, AshGraphql.Test.Movie do
      primary_key?(true)
      allow_nil?(false)
    end

    belongs_to :actor, AshGraphql.Test.Actor do
      primary_key?(true)
      allow_nil?(false)
    end
  end
end
