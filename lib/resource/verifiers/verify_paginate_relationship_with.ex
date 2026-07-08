# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Resource.Verifiers.VerifyPaginateRelationshipWith do
  # Validates the paginate_relationship_with option
  @moduledoc false

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  @valid_strategies [
    nil,
    :none,
    :keyset,
    :offset,
    :relay
  ]

  def verify(dsl) do
    many_relationships =
      dsl
      |> Verifier.get_entities([:relationships])
      |> Enum.filter(&(&1.cardinality == :many))
      |> Map.new(&{&1.name, &1})

    dsl
    |> Verifier.get_option([:graphql], :paginate_relationship_with, [])
    |> Enum.each(fn {relationship_name, config} ->
      strategy = strategy(config)

      cond do
        not Map.has_key?(many_relationships, relationship_name) ->
          module = Verifier.get_persisted(dsl, :module)

          raise Spark.Error.DslError,
            module: module,
            path: [:graphql, :paginate_relationship_with],
            message: """
            #{relationship_name} is not a relationship with cardinality many.
            """

        strategy not in @valid_strategies ->
          module = Verifier.get_persisted(dsl, :module)
          choices = Enum.map_join(@valid_strategies, ", ", &inspect/1)

          raise Spark.Error.DslError,
            module: module,
            path: [:graphql, :paginate_relationship_with],
            message: """
            #{inspect(strategy)} is not a valid pagination strategy for relationships.

            Available strategies: #{choices}
            """

        true ->
          validate_config(dsl, Map.fetch!(many_relationships, relationship_name), config)
      end
    end)
  end

  defp strategy(config) when is_list(config), do: Keyword.get(config, :strategy)
  defp strategy(strategy), do: strategy

  defp validate_config(dsl, relationship, config) when is_list(config) do
    module = Verifier.get_persisted(dsl, :module)
    edge_config = Keyword.get(config, :edge, []) || []
    fields = Keyword.get(edge_config, :fields, [])

    validate_name!(module, config, :name, [
      :graphql,
      :paginate_relationship_with,
      relationship.name
    ])

    validate_name!(module, config, :type_name, [
      :graphql,
      :paginate_relationship_with,
      relationship.name
    ])

    validate_name!(module, edge_config, :name, [
      :graphql,
      :paginate_relationship_with,
      relationship.name,
      :edge
    ])

    validate_name!(module, edge_config, :type_name, [
      :graphql,
      :paginate_relationship_with,
      relationship.name,
      :edge
    ])

    if fields != [] do
      if strategy(config) != :relay do
        raise Spark.Error.DslError,
          module: module,
          path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
          message: """
          Edge fields can only be configured when the relationship strategy is :relay.
          """
      end

      if relationship.type != :many_to_many do
        raise Spark.Error.DslError,
          module: module,
          path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
          message: """
          Edge fields can only be configured for many_to_many relationships.
          """
      end

      Enum.each(fields, fn field ->
        validate_join_field!(module, relationship, field)
      end)
    end
  end

  defp validate_config(_dsl, _relationship, _config), do: :ok

  defp validate_name!(module, config, key, path) do
    case Keyword.get(config, key) do
      nil ->
        :ok

      value when is_atom(value) ->
        :ok

      value ->
        raise Spark.Error.DslError,
          module: module,
          path: path,
          message: """
          Expected `#{key}` to be an atom, got: #{inspect(value)}
          """
    end
  end

  defp validate_join_field!(module, relationship, field_config) do
    field = edge_field_source(field_config)

    unless is_atom(field) do
      raise Spark.Error.DslError,
        module: module,
        path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
        message: """
        Edge fields must be atoms or `{field, opts}` tuples, got: #{inspect(field_config)}
        """
    end

    validate_edge_field_name!(module, relationship, field_config)

    cond do
      Ash.Resource.Info.attribute(relationship.through, field) ->
        :ok

      Ash.Resource.Info.aggregate(relationship.through, field) ->
        :ok

      Ash.Resource.Info.calculation(relationship.through, field) ->
        :ok

      join_relationship = Ash.Resource.Info.relationship(relationship.through, field) ->
        validate_relationship_destination_type!(module, relationship, join_relationship, field)

      true ->
        available =
          relationship.through
          |> available_join_fields()
          |> Enum.sort()

        raise Spark.Error.DslError,
          module: module,
          path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
          message: """
          Unknown field `#{inspect(field)}` on join resource #{inspect(relationship.through)}.

          Available: #{inspect(available)}
          """
    end
  end

  defp validate_edge_field_name!(module, relationship, {_field, opts}) when is_list(opts) do
    validate_name!(
      module,
      opts,
      :name,
      [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields]
    )
  end

  defp validate_edge_field_name!(module, relationship, {_field, name}) when not is_atom(name) do
    raise Spark.Error.DslError,
      module: module,
      path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
      message: """
      Expected edge field name override to be an atom, got: #{inspect(name)}
      """
  end

  defp validate_edge_field_name!(_module, _relationship, _field), do: :ok

  defp edge_field_source({field, _opts}), do: field
  defp edge_field_source(field), do: field

  defp validate_relationship_destination_type!(module, relationship, join_relationship, field) do
    if graphql_type(join_relationship.destination) do
      :ok
    else
      raise Spark.Error.DslError,
        module: module,
        path: [:graphql, :paginate_relationship_with, relationship.name, :edge, :fields],
        message: """
        Cannot expose relationship field `#{inspect(field)}` because #{inspect(join_relationship.destination)} does not define a GraphQL type.
        """
    end
  end

  defp graphql_type(resource) do
    AshGraphql.Resource.Info.type(resource)
  rescue
    _ -> nil
  end

  defp available_join_fields(resource) do
    Enum.map(Ash.Resource.Info.attributes(resource), & &1.name) ++
      Enum.map(Ash.Resource.Info.aggregates(resource), & &1.name) ++
      Enum.map(Ash.Resource.Info.calculations(resource), & &1.name) ++
      Enum.map(Ash.Resource.Info.relationships(resource), & &1.name)
  end
end
