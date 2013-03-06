function add_profile() {
  var row = '<tr>' +
            '<td> upload SAXS profile <input type="file" ' +
                     'name="uploaded_file"  /></td>' +
            '</tr>'
  $(row).appendTo("#profiles");
}
