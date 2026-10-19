return {
    name = "Session",
    fields = {
        {fieldname = "token", fieldtype = "Data", required = true, unique = true},
        {fieldname = "user_id", fieldtype = "Link", required = true},
        {fieldname = "expires_at", fieldtype = "Datetime", required = true},
        {fieldname = "ip", fieldtype = "Data"},
        {fieldname = "user_agent", fieldtype = "Text"},
    }
}
