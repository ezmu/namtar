return {
    name = "Article",
    fields = {
        {fieldname = "title", fieldtype = "Data", required = true},
        {fieldname = "slug", fieldtype = "Data", required = true, unique = true},
        {fieldname = "excerpt", fieldtype = "Text"},
        {fieldname = "body", fieldtype = "Text"},
        {fieldname = "status", fieldtype = "Select",
         options = {"draft", "published", "archived"}, default = "draft"},
        {fieldname = "author_id", fieldtype = "Link"},
        {fieldname = "views", fieldtype = "Int", default = 0},
        {fieldname = "published_at", fieldtype = "Datetime"},
    }
}
