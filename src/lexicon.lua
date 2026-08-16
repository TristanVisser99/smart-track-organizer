---@meta

---@class CategoryDefinition
---@field key string
---@field label string
---@field prefix string
---@field tokens string[]
---@field role_order string[]
---@field fx_clues string[]
---@field order? integer

---@class LexiconModule
---@field categories CategoryDefinition[]
---@field category_by_key table<string, CategoryDefinition>
---@field acronyms table<string, string>
---@field removable_prefixes string[]
local lexicon = {}

lexicon.categories = {
  {
    key = "drums",
    label = "Drums",
    prefix = "DRM",
    tokens = {
      "drum", "drums", "kick", "kik", "bd", "bass drum", "kick in", "kick out", "sub kick",
      "snare", "snr", "sd", "snare top", "snare bot", "snare bottom", "snare side", "rim", "rimshot", "clap", "snap",
      "hat", "hats", "hihat", "hi-hat", "hi hat", "hh", "hat open", "hat closed", "hat pedal",
      "tom", "toms", "rack tom", "floor tom", "tom1", "tom2", "tom3", "tom4", "hi tom", "mid tom", "low tom",
      "ride", "crash", "splash", "china", "cymbal", "cymbals", "cym",
      "overhead", "overheads", "oh", "oh l", "oh r",
      "drum room", "drums room", "kit room", "room close", "room far", "crush mic", "crotch mic",
      "perc", "percussion", "conga", "bongo", "shaker", "tambourine", "tamb", "cowbell", "cabasa", "guiro", "timbales",
      "808", "909", "breakbeat", "loop", "drum loop", "top loop"
    },
    role_order = {
      "sub kick", "kick in", "kick out", "kick", "kik", "bd", "bass drum",
      "snare top", "snare bot", "snare bottom", "snare side", "snare", "snr", "sd", "rim", "rimshot", "clap", "snap",
      "hat closed", "hat open", "hat pedal", "hihat", "hi-hat", "hi hat", "hh", "hat",
      "rack tom", "tom1", "tom2", "tom3", "tom4", "hi tom", "mid tom", "low tom", "floor tom", "tom", "toms",
      "ride", "crash", "splash", "china", "cymbal", "cymbals", "overhead", "overheads", "oh",
      "drum room", "drums room", "kit room", "room close", "room far", "crush mic",
      "perc", "percussion", "conga", "bongo", "shaker", "tambourine", "tamb", "cowbell"
    },
    fx_clues = { "superior drummer", "ezdrummer", "addictive drums", "kontakt drums", "battery", "steven slate" }
  },
  {
    key = "bass",
    label = "Bass",
    prefix = "BAS",
    tokens = {
      "bass", "bass gtr", "electric bass", "bass guitar", "sub", "sub bass", "808 bass", "808 sub",
      "synth bass", "reese bass", "acid bass", "upright bass", "upright", "acoustic bass", "fretless",
      "bass di", "bass mic", "bass amp", "low end"
    },
    role_order = { "sub", "sub bass", "808 bass", "808 sub", "synth bass", "bass di", "bass mic", "bass amp", "bass", "electric bass", "upright" },
    fx_clues = { "trilian", "ampeg", "darkglass", "bass amp", "sublab" }
  },
  {
    key = "vocals",
    label = "Vocals",
    prefix = "VOX",
    tokens = {
      "vox", "vocal", "vocals", "lead vox", "lead vocal", "ld vox", "ld vocal", "main vox",
      "backing", "backing vox", "backing vocal", "bvox", "bgv", "bgvs", "backings",
      "double", "dbl", "vocal dbl", "vox dbl", "vox l", "vox r",
      "harmony", "harmonies", "harm", "high harm", "mid harm", "low harm",
      "adlib", "ad lib", "adlibs", "shout", "chant", "whisper",
      "choir", "vocal group", "vocoder", "talkbox", "autotune", "tune"
    },
    role_order = {
      "lead vox", "lead vocal", "ld vox", "main vox", "vocal", "vox",
      "double", "dbl", "vox dbl", "harmony", "harmonies", "high harm", "mid harm", "low harm",
      "backing vox", "backing vocal", "bvox", "bgv", "bgvs", "backing",
      "adlib", "ad lib", "adlibs", "shout", "chant", "choir", "vocoder"
    },
    fx_clues = { "autotune", "melodyne", "vocoder", "de-esser", "vocal rider", "nectar" }
  },
  {
    key = "guitars",
    label = "Guitars",
    prefix = "GTR",
    tokens = {
      "gtr", "guitar", "guitars", "acoustic", "ac gtr", "acoustic gtr", "acoustic guitar", "nylon",
      "electric", "elec gtr", "electric gtr", "electric guitar", "egtr",
      "rhythm gtr", "rhy gtr", "lead gtr", "clean gtr", "clean guitar", "crunch gtr",
      "dist gtr", "dist guitar", "heavy gtr", "solo gtr", "guitar solo",
      "gtr di", "gtr amp", "gtr mic", "12 string", "dobro", "mandolin", "banjo"
    },
    role_order = {
      "acoustic gtr", "acoustic guitar", "ac gtr", "acoustic", "nylon",
      "rhythm gtr", "rhy gtr", "clean gtr", "clean guitar", "crunch gtr",
      "dist gtr", "dist guitar", "heavy gtr", "lead gtr", "solo gtr", "guitar solo",
      "gtr di", "gtr amp", "gtr", "guitar"
    },
    fx_clues = { "guitar rig", "amplitube", "helix", "bias amp", "neural dsp", "archon", "plini" }
  },
  {
    key = "keys",
    label = "Keys",
    prefix = "KEY",
    tokens = {
      "keys", "keyboard", "keyboards", "piano", "grand piano", "upright piano", "ac piano",
      "rhodes", "wurli", "wurlitzer", "epiano", "electric piano", "e-piano",
      "organ", "hammond", "b3", "clav", "clavinet", "mellotron", "harpsichord", "celeste", "accordian"
    },
    role_order = { "grand piano", "piano", "rhodes", "wurli", "wurlitzer", "epiano", "electric piano", "organ", "hammond", "clav", "keys" },
    fx_clues = { "keyscape", "pianoteq", "the grander", "vintage org", "lounge lizard" }
  },
  {
    key = "synths",
    label = "Synths",
    prefix = "SYN",
    tokens = {
      "synth", "synths", "synthesizer", "pad", "synth pad", "lead synth", "synth lead",
      "arp", "arpeggio", "pluck", "synth pluck", "stab", "poly synth", "mono synth",
      "sequence", "seq", "synth seq", "texture", "drone", "modular", "wavetable"
    },
    role_order = { "synth pad", "pad", "lead synth", "synth lead", "synth pluck", "pluck", "arp", "arpeggio", "sequence", "seq", "synth" },
    fx_clues = { "serum", "vital", "massive", "diva", "pigments", "sylenth", "spire", "omnisphere" }
  },
  {
    key = "strings",
    label = "Strings",
    prefix = "STR",
    tokens = {
      "string", "strings", "violin", "violins", "vln", "viola", "violas", "vla",
      "cello", "cellos", "vc", "contrabass", "double bass", "cb", "harp",
      "pizzicato", "spiccato", "legato strings", "orchestral strings"
    },
    role_order = { "violin", "violins", "viola", "violas", "cello", "cellos", "contrabass", "harp", "strings" },
    fx_clues = { "spitfire", "cinematic strings", "eastwest strings", "orchestral tools", "bbc so" }
  },
  {
    key = "brass",
    label = "Brass/Winds",
    prefix = "HORN",
    tokens = {
      "brass", "horn", "horns", "trumpet", "tpt", "trombone", "trb", "french horn", "tuba",
      "sax", "saxophone", "alto sax", "tenor sax", "bari sax", "soprano sax",
      "woodwind", "woodwinds", "flute", "clarinet", "oboe", "bassoon", "recorder"
    },
    role_order = { "trumpet", "french horn", "trombone", "tuba", "alto sax", "tenor sax", "bari sax", "sax", "flute", "clarinet", "oboe", "brass" },
    fx_clues = { "vintage horns", "session horns", "swam brass", "samplemodeling" }
  },
  {
    key = "fx",
    label = "FX",
    prefix = "FX",
    tokens = {
      "fx", "sfx", "riser", "impact", "sweep", "whoosh", "noise", "white noise", "sub drop", "drop",
      "downlifter", "uplifter", "reverse", "transition", "foley", "glitch", "zap", "laser", "boom", "hit"
    },
    role_order = { "riser", "uplifter", "impact", "hit", "sub drop", "downlifter", "sweep", "whoosh", "transition", "fx" },
    fx_clues = {}
  },
  {
    key = "returns",
    label = "Returns/Buses",
    prefix = "BUS",
    tokens = {
      "bus", "buss", "aux", "send", "return", "submix", "stem bus", "stem submix", "stems bus", "group bus", "vca",
      "reverb", "verb", "plate", "hall", "room verb", "spring verb",
      "delay", "echo", "tape delay", "throw", "slap",
      "parallel", "crush", "sidechain", "sc"
    },

    role_order = { "reverb", "verb", "plate", "delay", "echo", "parallel", "crush", "drum bus", "vox bus", "mix bus", "bus", "aux", "return" },
    fx_clues = { "valhalla", "pro-r", "fabfilter pro-r", "echoboy", "soundtoys" }
  },
  {
    key = "reference",
    label = "Reference",
    prefix = "REF",
    tokens = {
      "ref", "reference", "rough", "rough mix", "demo", "guide", "guide track",
      "print", "bounce", "master", "master mix", "click", "metronome", "slate", "count"
    },
    role_order = { "reference", "ref", "rough", "demo", "guide", "print", "bounce", "master", "click" },
    fx_clues = {}
  },
  {
    key = "other",
    label = "Other",
    prefix = "MISC",
    tokens = {},
    role_order = {},
    fx_clues = {}
  }
}

lexicon.category_by_key = {}
for index, category in ipairs(lexicon.categories) do
  category.order = index
  lexicon.category_by_key[category.key] = category
end

lexicon.acronyms = {
  di = "DI",
  fx = "FX",
  eq = "EQ",
  midi = "MIDI",
  bgv = "BGV",
  bgvs = "BGVs",
  bvox = "BVOX",
  vox = "VOX",
  dbl = "DBL",
  vca = "VCA",
  oh = "OH",
  ny = "NY",
  lr = "L/R",
  l = "L",
  r = "R",
  sfx = "SFX"
}

lexicon.removable_prefixes = {
  "DRM", "BAS", "VOX", "GTR", "KEY", "SYN", "STR", "HORN", "FX", "BUS", "REF", "MISC"
}

return lexicon
