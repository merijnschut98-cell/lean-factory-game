class_name ConceptDef
extends RefCounted
## One glossary entry from content/concepts.yaml (the codex): a concept the
## game teaches, in Dutch, with an example from Voltana.

const CATEGORIES := ["lean", "sector", "kata", "measure"]

var id: String
var name: String
var category: String
## One sentence for the codex list.
var short: String
## Two to four sentences for the codex page.
var text: String
var example: String
## Sector entries: the public source's title, or the reasoning behind an estimate.
var source_title := ""
var estimate := ""
var error := ""


static func from_dict(d: Dictionary) -> ConceptDef:
	var c := ConceptDef.new()
	c.id = str(d.get("id", ""))
	c.name = str(d.get("name", ""))
	c.category = str(d.get("category", ""))
	c.short = str(d.get("short", ""))
	c.text = str(d.get("text", ""))
	c.example = str(d.get("example", ""))
	var source = d.get("source")
	if source is Dictionary:
		c.source_title = str(source.get("title", ""))
	c.estimate = str(d.get("estimate", ""))
	if c.id.is_empty() or c.name.is_empty() or c.short.is_empty():
		c.error = "concept %s: needs an id, a name and a short text" % c.id
	elif not c.category in CATEGORIES:
		c.error = "concept %s: 'category' must be one of %s" % [c.id, CATEGORIES]
	return c
