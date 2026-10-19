return {
    name = "Setting",
    fields = {
        {fieldname = "key", fieldtype = "Data", required = true, unique = true},
        {fieldname = "value", fieldtype = "Text"},
        {fieldname = "group", fieldtype = "Data", default = "general"},
    }
}
