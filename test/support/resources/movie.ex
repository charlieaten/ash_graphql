# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Test.Movie do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshGraphql.Resource]

  graphql do
    type(:movie)

    paginate_relationship_with(
      actors: [
        strategy: :relay,
        name: :movie_actors_connection,
        edge: [
          name: :movie_actors_edge,
          fields: [:position, :distance_meters, :movie]
        ]
      ],
      selected_actors: [
        strategy: :relay,
        name: :movie_selected_actors_connection,
        edge: [
          name: :movie_selected_actors_edge,
          fields: [:rating]
        ]
      ],
      reviews: :offset,
      awards: :keyset,
      unrelated_actors: :relay
    )

    queries do
      get :get_movie, :read do
        meta meta_string: "bar", meta_integer: 1
      end

      list :get_movies, :read, paginate_with: nil
    end

    mutations do
      create :create_movie, :create_with_actors

      update :update_movie, :update do
        meta meta_string: "bar", meta_integer: 1
      end

      destroy :destroy_movie, :destroy
    end
  end

  actions do
    default_accept(:*)
    defaults([:create, :read, :update, :destroy])

    create :create_with_actors do
      argument :actor_ids, {:array, :uuid} do
        allow_nil? false
        constraints(min_length: 1)
      end

      change(manage_relationship(:actor_ids, :actors, type: :append))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:title, :string, public?: true)
  end

  relationships do
    many_to_many(:actors, AshGraphql.Test.Actor,
      through: AshGraphql.Test.MovieActor,
      public?: true
    )

    has_many :selected_actor_join_rows, AshGraphql.Test.MovieActorSelection do
      destination_attribute(:movie_id)
      filter(expr(selected == true))
    end

    many_to_many :selected_actors, AshGraphql.Test.Actor do
      join_relationship(:selected_actor_join_rows)
      source_attribute_on_join_resource(:movie_id)
      destination_attribute_on_join_resource(:actor_id)
      unique_on_join_relationship? true
      public?(true)
    end

    has_many(:unrelated_actors, AshGraphql.Test.Actor,
      no_attributes?: true,
      public?: true
    )

    has_many(:reviews, AshGraphql.Test.Review, public?: true)
    has_many(:awards, AshGraphql.Test.Award, public?: true)
  end
end
