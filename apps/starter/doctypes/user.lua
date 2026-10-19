return {
    name = "User",
    fields = {
        {fieldname = "email", fieldtype = "Data", required = true, unique = true},
        {fieldname = "username", fieldtype = "Data", required = true, unique = true},
        {fieldname = "password_hash", fieldtype = "Data", required = true},
        {fieldname = "salt", fieldtype = "Data", required = true},
        {fieldname = "full_name", fieldtype = "Data"},
        {fieldname = "role", fieldtype = "Select",
         options = {"admin", "editor", "user"}, default = "user"},
        {fieldname = "active", fieldtype = "Check", default = 1},
        {fieldname = "last_login", fieldtype = "Datetime"},
    }
}
