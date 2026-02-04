# #0010 - StargateLDtk Loader (Legacy Path Adapter)
require_relative "core/world.rb"
require_relative "core/loader.rb"

# #0013
require_relative "analysis/spatial.rb"
require_relative "services/ergonomics.rb"

# #0014
require_relative "render/world_renderer.rb"

# #0015
require_relative "tactics/intention.rb"
require_relative "tactics/decision.rb"
require_relative "tactics/temporal.rb"
require_relative "tactics/interpreter.rb"

# #0016
require_relative "adapters/ldtk_to_dr.rb"

# #0017 - The Bridge 🌉
require_relative "bridge.rb"

# #0018 - Causal Reconstruction Layer
require_relative "reconstruction.rb"

puts "🌌 StargateLDtk v0.8.0-alpha: Initialized via Adapter Loader."
