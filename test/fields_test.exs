# SPDX-FileCopyrightText: 2020 ash_graphql contributors <https://github.com/ash-project/ash_graphql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshGraphql.FieldsTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      AshGraphql.TestHelpers.stop_ets()
    end)
  end

  test "fields block controls exposure, names, sources, and default nullability" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "ExplicitFields") {
          fields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    fields = Map.new(data["__type"]["fields"], &{&1["name"], &1})

    assert fields |> Map.keys() |> Enum.sort() == ["code", "name", "publicNote"]
    assert fields["code"]["type"]["kind"] == "NON_NULL"
    assert fields["code"]["type"]["ofType"]["name"] == "ID"
    assert fields["name"]["type"]["kind"] == "SCALAR"
    assert fields["name"]["type"]["name"] == "String"
    assert fields["publicNote"]["type"]["kind"] == "SCALAR"
    assert fields["publicNote"]["type"]["name"] == "String"

    {:ok, %{data: data}} =
      """
      query {
        __type(name: "CreateExplicitFieldsInput") {
          inputFields {
            name
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    input_fields = Enum.map(data["__type"]["inputFields"], & &1["name"])

    assert Enum.sort(input_fields) == ["code", "internalName", "publicNote", "secret"]

    AshGraphql.Test.ExplicitFields
    |> Ash.Changeset.for_create(:create, %{
      code: "US",
      internal_name: "United States",
      public_note: "visible",
      secret: "hidden"
    })
    |> Ash.create!()

    AshGraphql.Test.ExplicitFieldTranslation
    |> Ash.Changeset.for_create(:create, %{
      explicit_field_code: "US",
      name: "Estados Unidos"
    })
    |> Ash.create!()

    assert {:ok,
            %{
              data: %{
                "explicitField" => %{
                  "code" => "US",
                  "name" => "Estados Unidos",
                  "publicNote" => "visible"
                }
              }
            }} =
             """
             query {
               explicitField(code: "US") {
                 code
                 name
                 publicNote
               }
             }
             """
             |> Absinthe.run(AshGraphql.Test.Schema)

    assert {:ok,
            %{
              data: %{
                "customGetExplicitFieldUnloaded" => %{
                  "code" => "US",
                  "name" => "Estados Unidos",
                  "publicNote" => "visible"
                }
              }
            }} =
             """
             query {
               customGetExplicitFieldUnloaded(code: "US") {
                 code
                 name
                 publicNote
               }
             }
             """
             |> Absinthe.run(AshGraphql.Test.Schema)
  end
end
