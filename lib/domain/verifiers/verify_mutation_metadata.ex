# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Domain.Verifiers.VerifyMutationMetadata do
  @moduledoc false
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Transformer

  def verify(dsl) do
    module = Transformer.get_persisted(dsl, :module)

    dsl
    |> AshGraphql.Domain.Info.mutations()
    |> Enum.each(fn mutation ->
      AshGraphql.Resource.Verifiers.VerifyMutationMetadata.verify_mutation!(
        module,
        mutation,
        mutation.resource
      )
    end)

    :ok
  end
end
