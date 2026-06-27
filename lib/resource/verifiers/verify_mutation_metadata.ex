# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Resource.Verifiers.VerifyMutationMetadata do
  @moduledoc false
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Transformer

  def verify(dsl) do
    resource = Transformer.get_persisted(dsl, :module)

    dsl
    |> AshGraphql.Resource.Info.mutations([])
    |> Enum.each(&verify_mutation!(resource, &1, resource))

    :ok
  end

  def verify_mutation!(
        module,
        %AshGraphql.Resource.Mutation{
          type: type,
          error_location: :top_level,
          action: action_name
        } = mutation,
        resource
      )
      when type in [:create, :update, :destroy] do
    action = Ash.Resource.Info.action(resource, action_name)
    metadata = Map.get(action, :metadata, [])

    if !Enum.empty?(metadata) do
      raise Spark.Error.DslError,
        module: module,
        path: [:graphql, :mutations, mutation.name],
        message: """
        Mutation #{inspect(mutation.name)} uses `error_location :top_level`, but action #{inspect(action_name)} exposes metadata.

        Top-level regular mutations return the resource type directly, so action metadata cannot be selected.

        Use `error_location :in_result`, remove the action metadata, or expose this operation as a generic action mutation with a wrapper.

        Metadata fields:

        #{Enum.map_join(metadata, "\n", &"* #{&1.name}")}
        """
    end
  end

  def verify_mutation!(_module, _mutation, _resource), do: :ok
end
