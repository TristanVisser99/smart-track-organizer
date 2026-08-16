local core = require("smart_track_organizer_core")
local adapter = require("reaper_adapter")

local ui_native = {}

function ui_native.launch(reaper_api)
  local ok, values = reaper_api.GetUserInputs(
    "Smart Track Organizer",
    4,
    "Scope: all or selected,Create folder groups? yes/no,Prefix renamed tracks? yes/no,Dry run? yes/no",
    "all,yes,yes,no"
  )
  if not ok then return end

  local fields = {}
  for field in (values .. ","):gmatch("([^,]*),") do
    fields[#fields + 1] = field:lower():gsub("^%s+", ""):gsub("%s+$", "")
  end

  local options = {
    selected_only = fields[1] == "selected",
    create_folders = fields[2] ~= "no",
    prefix_names = fields[3] ~= "no",
    dry_run = fields[4] == "yes"
  }

  local raw_tracks = adapter.collect_tracks(reaper_api)
  local plan = core.build_plan(raw_tracks, options)
  if #plan.tracks == 0 then
    reaper_api.ShowMessageBox("No tracks found for the selected scope.", "Smart Track Organizer", 0)
    return
  end

  if options.dry_run then
    local lines = { "Smart Track Organizer dry run", "", core.summarize_plan(plan), "" }
    for _, item in ipairs(plan.tracks) do
      lines[#lines + 1] = string.format("%02d. %-14s %s -> %s", item.new_index, item.category_label, item.original_name, item.new_name)
    end
    reaper_api.ShowMessageBox(table.concat(lines, "\n"), "Smart Track Organizer", 0)
    return
  end

  adapter.execute_plan(plan, reaper_api)
  reaper_api.ShowMessageBox(core.summarize_plan(plan), "Smart Track Organizer complete", 0)
end

return ui_native
