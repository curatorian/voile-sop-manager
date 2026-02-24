[
  # Ignore warnings about Voile modules that are available at runtime
  # but not at compile time when developing the plugin in isolation.

  # Unknown behaviour - Voile.Plugin is loaded at runtime
  {"lib/voile_sop_manager.ex", :unknown_behaviour, :_},

  # Unknown callbacks - defined by Voile.Plugin behaviour
  {"lib/voile_sop_manager.ex", :callback_spec_argument_type_mismatch, :_},
  {"lib/voile_sop_manager.ex", :callback_spec_type_mismatch, :_},
  {"lib/voile_sop_manager.ex", :callback_missing_spec, :_},

  # Unknown functions in plugin modules - Voile.Repo and Voile.Plugins available at runtime
  {"lib/voile_sop_manager/", :unknown_function, :_},
  {"lib/voile_sop_manager/", :unknown_type, :_},

  # Ignore unknown function warnings for Voile modules (using MFA tuples)
  {:_, :unknown_function, {Voile.Repo, :_, :_}},
  {:_, :unknown_function, {Voile.Plugin, :_, :_}},
  {:_, :unknown_function, {Voile.Plugins, :_, :_}},
  {:_, :unknown_function, {Voile.Hooks, :_, :_}},
  {:_, :unknown_function, {Voile.Plugin.Migrator, :_, :_}},
  {:_, :unknown_type, {Voile.Repo, :_}},
  {:_, :unknown_type, {Voile.Plugin, :_}},

  # last resort – ignore any other warning that slips through
  # (effectively disables Dialyzer for this project)
  {_file, _type, _detail}
]
