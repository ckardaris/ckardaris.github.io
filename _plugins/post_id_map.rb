Jekyll::Hooks.register :site, :post_read do |site|
  map = {}

  site.posts.each do |post|
    map[post.id] = {}
    map[post.id]["title"] = post.data["title"]
    map[post.id]["date"] = post.data["date"]
  end

  # Create yml file for use in scripts.
  data_path = File.join(site.source, "_scripts/data", "post_id_map.yml")
  FileUtils.mkdir_p(File.dirname(data_path))
  File.write(data_path, YAML.dump(map))

  # Also inject into site.data immediately.
  site.data["post_id_map"] = map
end
