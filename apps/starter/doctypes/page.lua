return {
    name = "Page",
    fields = {
        {fieldname = "title", fieldtype = "Data", required = true},
        {fieldname = "slug", fieldtype = "Data", required = true, unique = true},
        {fieldname = "body", fieldtype = "Text"},
        {fieldname = "status", fieldtype = "Select",
         options = {"draft", "published"}, default = "published"},
        {fieldname = "show_in_menu", fieldtype = "Check", default = 0},
        {fieldname = "menu_order", fieldtype = "Int", default = 0},
    }
}
