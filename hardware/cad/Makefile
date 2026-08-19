# Makefile — export printable STLs for the Exacto CAD models.
#
# One STL per part, written to ./out/:
#   Full sight housing : sight_top / sight_bottom / sight_bar / sight_lid
#   Minimal fixture     : sight_minimal_base / sight_minimal_head
#   Mega plate          : mega_plate_plate / mega_plate_bar
#
# Usage:
#   make              # build everything
#   make sight        # full + minimal sight housing
#   make sight-full   # top/bottom/bar/lid only
#   make sight-minimal
#   make plate        # mega plate parts
#   make clean        # remove ./out
#
# Override the binary or format:  make OPENSCAD=openscad-nightly FORMAT=asciistl

OPENSCAD ?= openscad
FORMAT   ?= binstl
OUT      := out

SIGHT_SRC := sight_housing.scad
PLATE_SRC := arduino_mega_plate.scad

# Printable parts (the `part` value passed to each model).
SIGHT_FULL_PARTS := top bottom bar lid
SIGHT_MIN_PARTS  := minimal_base minimal_head
PLATE_PARTS      := plate bar spacers

SIGHT_FULL := $(SIGHT_FULL_PARTS:%=$(OUT)/sight_%.stl)
SIGHT_MIN  := $(SIGHT_MIN_PARTS:%=$(OUT)/sight_%.stl)
PLATE      := $(PLATE_PARTS:%=$(OUT)/mega_plate_%.stl)

# Rebuild any part when any local .scad source changes (renders are cheap).
DEPS := $(wildcard *.scad scad-common/*.scad arduino-mount/*.scad pin_connectors/*.scad)

.PHONY: all sight sight-full sight-minimal plate clean
all: $(SIGHT_FULL) $(SIGHT_MIN) $(PLATE)
sight: sight-full sight-minimal
sight-full: $(SIGHT_FULL)
sight-minimal: $(SIGHT_MIN)
plate: $(PLATE)

# Sight housing: local `use <...>` paths resolve relative to the .scad file.
$(OUT)/sight_%.stl: $(SIGHT_SRC) $(DEPS) | $(OUT)
	$(OPENSCAD) --export-format $(FORMAT) -o $@ -D 'part="$*"' $(SIGHT_SRC)

# Mega plate: OPENSCADPATH lets arduino.scad find the pin_connectors submodule.
$(OUT)/mega_plate_%.stl: $(PLATE_SRC) $(DEPS) | $(OUT)
	OPENSCADPATH=$(CURDIR) $(OPENSCAD) --export-format $(FORMAT) -o $@ -D 'part="$*"' $(PLATE_SRC)

$(OUT):
	mkdir -p $(OUT)

clean:
	rm -rf $(OUT)
