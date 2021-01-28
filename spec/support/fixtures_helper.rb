def load_fixture(path)
  fixture_path = "#{Rails.root}/spec/fixtures/#{path}.json"
  obj = JSON.parse(File.read(fixture_path), object_class: OpenStruct)
  obj.save = true
  obj.destroy = true
  obj.reload = obj
  obj
end
