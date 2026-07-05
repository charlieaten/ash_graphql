# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.Resource.Field do
  @moduledoc "Represents a configured field on a resource's GraphQL type"

  defstruct [
    :name,
    :source,
    :__spark_metadata__,
    identity?: false
  ]
end
