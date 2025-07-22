# Gtk Support

LuaGObject's Gtk support is based on GObject-Introspection. In practice, this
means that Gtk3, Gtk4, and libadwaita ("Adw") should work out of the box.

Gtk4 and Adw support are provided without any additional features specific to
LuaGObject. Both libraries fully support introspection, and should function as
expected according to their API documentation.

For Gtk3, LuaGObject provides some extensions in order to support
unintrospectable features and to provide easier and more Lua-like access to
certain Gtk3 objects. The rest of this document describes enhancements
LuaGObject provides when using Gtk3.

To explicitly use Gtk3 in LuaGObject, pass the version parameter to
`LuaGObject.require` like so:

    local LuaGObject = require 'LuaGObject'
    local Gtk = LuaGObject.require('Gtk', '3.0')

Please note that different versions of the same library cannot be loaded at the
same time. This means if you've already loaded a library dependent on a
different version of Gtk (such as Adw or GtkSourceView-5), you won't be able
to load Gtk3.

Generally speaking, it's recommended to avoid Gtk3 for new applications unless
writing them for a platform that has not yet moved on to Gtk4 or newer. If this
is the case for you, read on.

## Basic Widget and Container support

### Accessing Style Properties

To read style property values of a widget, a `style` attribute is implemented by
LuaGObject. The following example reads the `resize-grip-height` style property
from a Gtk.Window instance:

    local window = Gtk.Window()
    print(window.style.resize_grip_height)

### Gtk.Widget Width and Height Properties

LuaGObject adds new `width` and `height` properties to Gtk.Widget. Reading them
yields allocated size (`Gtk.Widget.get_allocated_size()`), writing them sets
a new size request (`Gtk.Widget.set_size_request()`). These usages typically
mean what application logic needs: get the actual allocated size to draw on when
reading, and request a specific size when writing.

### Child Properties

Child properties are properties of the relation between a container and child.
A Lua-friendly access to these properties is implemented through the `property`
attribute of `Gtk.Container`. The following example illustrates writing and
reading of `width` property of `Gtk.Grid` and child `Gtk.Button`:

    local grid, button = Gtk.Grid(), Gtk.Button()
    grid:add(button)
    grid.property[button].width = 2
    print(grid.property[button].width)   -- prints 2

### Adding Children to a Container

The intended way to add children to a container is through the
`Gtk.Container.add()` method. This method is overloaded by LuaGObject so
that it accepts either a widget, or a table containing a widget at index 1 with
the rest of the `name=value` pairs defining the child's properties. Therefore,
this method is a full replacement of the unintrospectable
`gtk_container_add_with_properties()` function. Let's simplify the previous
section's example with this syntax:

    local grid, button = Gtk.Grid(), Gtk.Button()
    grid:add { button, width = 2 }
    print(grid.property[button].width)    -- prints 2

Another important feature of containers is that they have an extended
constructor, the constructor table argument's array part can contain widgets to
be added as children. The previous example can be simplified further as:

    local button = Gtk.Button()
    local grid = Gtk.Grid {
       { button, width = 2 }
    }
    print(grid.property[button].width)    -- prints 2

### Gtk.Widget `id` Property

Another important feature is that all widgets support the `id` property, which
can hold an arbitrary string which is used to identify the widget. `id` is
assigned by the user and defaults to `nil`. To find a widget using the specified
id in the container's widget tree (i.e. not only in direct container children),
query the `child` property of the container with the requested id. Rewriting the
previous example using this technique:

    local grid = Gtk.Grid {
       { Gtk.Button { id = 'button' }, width = 2 }
    }
    print(grid.property[grid.child.button].width)    -- prints 2

The advantage of these features is that they allow using Lua's data description
syntax for describing widget hierarchies in a natural way, instead of
`Gtk.Builder`'s human-unfriendly XML. To build a very complicated widget tree:

    Gtk = LuaGObject.Gtk
    local window = Gtk.Window {
       title = 'Application',
       default_width = 640, default_height = 480,
       Gtk.Grid {
          orientation = Gtk.Orientation.VERTICAL,
          Gtk.Toolbar {
             Gtk.ToolButton { id = 'about', stock_id = Gtk.STOCK_ABOUT },
             Gtk.ToolButton { id = 'quit', stock_id = Gtk.STOCK_QUIT },
          },
          Gtk.ScrolledWindow {
             Gtk.TextView { id = 'view', expand = true }
          },
          Gtk.Statusbar { id = 'statusbar' }
       }
    }

    local n = 0
    function window.child.about:on_clicked()
       n = n + 1
       window.child.view.buffer.text = 'Clicked ' .. n .. ' times'
    end

    function window.child.quit:on_clicked()
       window:destroy()
    end

    window:show_all()

Run `samples/console.lua`, paste the example into its entry view and enjoy.
The `samples/console.lua` example itself shows more complex usage of this
pattern.

## Gtk.Builder

Although Lua's declarative style for creating widget hierarchies is generally
preferred to builder's XML authoring by hand, `Gtk.Builder` can still be
useful when widget hierarchies are designed in some external tool like
`glade`.

Normally, `gtk_builder_add_from_file` and `gtk_builder_add_from_string`
return `guint` instead of `gboolean`, which would make direct usage
from Lua awkward. LuaGObject overrides these methods to return `boolean` as
the first return value, so that the construction
`assert(builder:add_from_file(filename))` can be used.

A new `objects` attribute provides direct access to loaded objects by
their identifier, so that instead of `builder:get_object('id')` it
is possible to use `builder.objects.id`

`Gtk.Builder.connect_signals(handlers)` tries to connect all signals
to handlers which are defined in `handlers` table. Functions from
`handlers` table are invoked with target object on which is signal
defined as first argument, but it is possible to define `object`
attribute, in this case the object instance specified in `object`
attribute is used. `after` attribute is honored, but `swapped` is
completely ignored, as its semantics for LuaGObject is unclear and not very
useful.

## Gtk.Action and Gtk.ActionGroup

LuaGObject provides new method `Gtk.ActionGroup:add()` which generally replaces
unintrospectable `gtk_action_group_add_actions()` family of functions.
`Gtk.ActionGroup:add()` accepts single argument, which may be one of:

- an instance of `Gtk.Action` - this is identical with calling
  `Gtk.Action.add_action()`.
- a table containing instance of `Gtk.Action` at index 1, and
  optionally having attribute `accelerator`; this is a shorthand for
  `Gtk.ActionGroup.add_action_with_accel()`
- a table with array of `Gtk.RadioAction` instances, and optionally
  `on_change` attribute containing function to be called when the radio
  group state is changed.

All actions or groups can be added by an array part of `Gtk.ActionGroup`
constructor, as demonstrated by following example:

    local group = Gtk.ActionGroup {
       Gtk.Action { name = 'new', label = "_New" },
       { Gtk.Action { name = 'open', label = "_Open" },
         accelerator = '<control>O' },
       {
          Gtk.RadioAction { name = 'simple', label = "_Simple", value = 1 },
          { Gtk.RadioAction { name = 'complex', label = "_Complex",
            value = 2 }, accelerator = '<control>C' },
          on_change = function(action)
             print("Changed to: ", action.name)
          end
       },
    }

To access specific action from the group, a read-only attribute `action`
is added to the group, which allows to be indexed by action name to
retrieve. So continuing the example above, we can implement 'new'
action like this:

    function group.action.new:on_activate()
       print("Action 'New' invoked")
    end

## Gtk.TextTagTable

It is possible to populate new instance of the tag table with tags
during the construction, an array part of constructor argument table is
expected to contain `Gtk.TextTag` instances which are then automatically
added to the table.

A new attribute `tag` is added, provides Lua table which can be indexed
by string representing tag name and returns the appropriate tag (so it is
essentially a wrapper around `Gtk.TextTagTable:lookup()` method).

Following example demonstrates both capabilities:

    local tag_table = Gtk.TextTagTable {
       Gtk.TextTag { name = 'plain', color = 'blue' },
       Gtk.TextTag { name = 'error', color = 'red' },
    }

    assert(tag_table.tag.plain == tag_table:lookup('plain'))

## TreeView and related classes

`Gtk.TreeView` and related classes like `Gtk.TreeModel` are one of the
most complicated objects in the whole `Gtk`. LuaGObject adds some overrides
to simplify the work with them.

### Gtk.TreeModel

LuaGObject supports direct indexing of treemodel instances by iterators
(i.e. `Gtk.TreeIter` instances). To get value at specified column
number, index the resulting value again with column number. Note that
although `Gtk` uses 0-based column numbers, LuaGObject remaps them to 1-based
numbers, because working with 1-based arrays is much more natural for
Lua.

Another extension provided by LuaGObject is
`Gtk.TreeModel:pairs([parent_iter])` method for Lua-native iteration of
the model. This method returns 3 values suitable to pass to generic
`for`, so that standard Lua iteration protocol can be used. See the
example in the next chapter which uses this technique.

### Gtk.ListStore and Gtk.TreeStore

Standard `Gtk.TreeModel` implementations, `Gtk.ListStore` and
`Gtk.TreeStore` extend the concept of indexing model instance with
iterators also to writing values. Indexing resulting value with
1-based column number allows writing individual values, while
assigning the table containing column-keyed values allows assigning
multiple values at once. Following example illustrates all these
techniques:

    local PersonColumn = { NAME = 1, AGE = 2, EMPLOYEE = 3 }
    local store = Gtk.ListStore.new {
       [PersonColumn.NAME] = GObject.Type.STRING,
       [PersonColumn.AGE] = GObject.Type.INT,
       [PersonColumn.EMPLOYEE] = GObject.Type.BOOLEAN,
    }
    local person = store:append()
    store[person] = {
       [PersonColumn.NAME] = "John Doe",
       [PersonColumn.AGE] = 45,
       [PersonColumn.EMPLOYEE] = true,
    }
    assert(store[person][PersonColumn.AGE] == 45)
    store[person][PersonColumn.AGE] = 42
    assert(store[person][PersonColumn.AGE] == 42)

    -- Print all persons in the store
    for i, p in store:pairs() do
       print(p[PersonColumn.NAME], p[PersonColumn.AGE])
    end

Note that `append` and `insert` methods are overridden and accept
additional parameter containing table with column/value pairs, so
creation section of previous example can be simplified to:

    local person = store:append {
       [PersonColumn.NAME] = "John Doe",
       [PersonColumn.AGE] = 45,
       [PersonColumn.EMPLOYEE] = true,
    }

Note that you also can use numbers or strings as indexes. Useful
example is reading values selected from `Gtk.ComboBox`:

    local index = MyComboBox:get_active() -- Index is string, but numbers is also supported
    print("Active index: ", index)
    print("Selected value: ", MyStore[index])

Note that while the example uses `Gtk.ListStore`, similar overrides
are provided also for `Gtk.TreeStore`.

### Gtk.TreeView and Gtk.TreeViewColumn

LuaGObject provides `Gtk.TreeViewColumn:set(cell, data)` method, which allows
assigning either a set of `cell` renderer attribute->model column
pairs (in case that `data` argument is a table), or assigns custom
data function for specified cell renderer (when `data` is a function).
Note that column must already have assigned cell renderer. See
`gtk_tree_view_column_set_attributes()` and
`gtk_tree_view_column_set_cell_data_func()` for precise documentation.

The override `Gtk.TreeViewColumn:add(def)` composes both adding new
cellrenderer and setting attributes or data function. `def` argument
is a table, containing cell renderer instance at index 1 and `data` at
index 2. Optionally, it can also contain `expand` attribute (set to
`true` or `false`) and `align` (set either to `start` or `end`). This
method is basically combination of `gtk_tree_view_column_pack_start()`
or `gtk_tree_view_column_pack_end()` and `set()` override method.

Array part of `Gtk.TreeViewColumn` constructor call is mapped to call
`Gtk.TreeViewColumn:add()` method, and array part of `Gtk.TreeView`
constructor call is mapped to call `Gtk.TreeView:append_column()`, and
this allows composing the whole initialized treeview in a declarative
style like in the example below:

    -- This example reuses 'store' model created in examples in
    -- Gtk.TreeModel chapter.
    local view = Gtk.TreeView {
       model = store,
       Gtk.TreeViewColumn {
          title = "Name and age",
          expand = true,
          { Gtk.CellRendererText {}, { text = PersonColumn.NAME } },
          { Gtk.CellRendererText {}, { text = PersonColumn.AGE } },
       },
       Gtk.TreeViewColumn {
          title = "Employee",
          { Gtk.CellRendererToggle {}, { active = PersonColumn.EMPLOYEE } }
       },
    }
