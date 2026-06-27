# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.VerifyMutationMetadataTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  defmodule TestDomain do
    use Ash.Domain, extensions: [AshGraphql.Domain]

    resources do
      allow_unregistered?(true)
    end
  end

  test "raises for resource-level top-level regular mutation with action metadata" do
    output =
      capture_io(:stderr, fn ->
        defmodule ResourceLevelMetadataTopLevel do
          use Ash.Resource,
            domain: TestDomain,
            extensions: [AshGraphql.Resource]

          graphql do
            type(:resource_level_metadata_top_level)

            mutations do
              create(:create_resource_level_metadata_top_level, :create,
                error_location: :top_level
              )
            end
          end

          actions do
            default_accept(:*)

            create :create do
              metadata(:foo, :string)
            end
          end

          attributes do
            uuid_primary_key(:id)
          end
        end
      end)

    assert output =~ "Spark.Error.DslError"
    assert output =~ "error_location :top_level"
    assert output =~ "action metadata cannot be selected"
  end

  test "raises for domain-level top-level regular mutation with action metadata" do
    output =
      capture_io(:stderr, fn ->
        defmodule DomainLevelMetadataTopLevel do
          use Ash.Domain, extensions: [AshGraphql.Domain]

          graphql do
            mutations do
              create(AshGraphql.Test.Post, :domain_level_metadata_top_level, :create,
                error_location: :top_level
              )
            end
          end

          resources do
            allow_unregistered?(true)
          end
        end
      end)

    assert output =~ "Spark.Error.DslError"
    assert output =~ "error_location :top_level"
    assert output =~ "action metadata cannot be selected"
  end

  test "allows metadata on regular mutations that keep errors in the result" do
    defmodule ResourceLevelMetadataInResult do
      use Ash.Resource,
        domain: TestDomain,
        extensions: [AshGraphql.Resource]

      graphql do
        type(:resource_level_metadata_in_result)

        mutations do
          create(:create_resource_level_metadata_in_result, :create, error_location: :in_result)
        end
      end

      actions do
        default_accept(:*)

        create :create do
          metadata(:foo, :string)
        end
      end

      attributes do
        uuid_primary_key(:id)
      end
    end
  end

  test "allows top-level regular mutations without action metadata" do
    defmodule ResourceLevelNoMetadataTopLevel do
      use Ash.Resource,
        domain: TestDomain,
        extensions: [AshGraphql.Resource]

      graphql do
        type(:resource_level_no_metadata_top_level)

        mutations do
          create(:create_resource_level_no_metadata_top_level, :create,
            error_location: :top_level
          )
        end
      end

      actions do
        default_accept(:*)
        defaults([:create])
      end

      attributes do
        uuid_primary_key(:id)
      end
    end
  end
end
