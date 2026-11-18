function transform(line) {
  var fields = line.split(",");
  return JSON.stringify({
    id: Number(fields[0]),
    title: fields[1],
    attendee_count: Number(fields[2]),
  });
}
