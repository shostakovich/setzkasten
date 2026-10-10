%{
  configs: [
    %{
      name: "default",
      files: %{included: ["lib/", "dev/lib/", "test/"], excluded: []},
      strict: true,
      checks: %{
        disabled: [
          {Credo.Check.Readability.Specs, []},
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}
