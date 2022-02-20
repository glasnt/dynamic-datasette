# Process Upload

Takes a POST body containing an `upload_bucket` and `upload_file` value, and converts it to an SQLite database, depending on the file type.

Requires `DATASETTE_BUCKET` to be defined as the upload target.