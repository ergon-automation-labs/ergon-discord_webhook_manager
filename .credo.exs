%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.AliasOrder, false},
        {Credo.Check.Design.AliasUsage, false}
      ]
    }
  ]
}
