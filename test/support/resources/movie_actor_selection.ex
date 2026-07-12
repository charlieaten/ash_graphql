# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Test.MovieActorSelection do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults([:read])

    create :create do
      primary?(true)
      accept([:movie_id, :actor_id, :rating, :selected])
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:rating, :integer, public?: false)
    attribute(:selected, :boolean, public?: false, allow_nil?: false, default: false)
  end

  relationships do
    belongs_to :movie, AshGraphql.Test.Movie do
      allow_nil?(false)
    end

    belongs_to :actor, AshGraphql.Test.Actor do
      allow_nil?(false)
    end
  end
end
