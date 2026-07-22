require SeedHelper
import SeedHelper

alias GottaCc.Schema.Directory.Category
# Directory categories (changelog 025). Idempotent: on_conflict :nothing by id.
seed {"directory-category:technology", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Technology"),
      slug: "technology",
      name: "Technology",
      display_order: 0
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"directory-category:culture", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Culture"),
      slug: "culture",
      name: "Culture",
      display_order: 1
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"directory-category:science", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Science"),
      slug: "science",
      name: "Science",
      display_order: 2
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"directory-category:making-crafts", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Making & Crafts"),
      slug: "making-crafts",
      name: "Making & Crafts",
      display_order: 3
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"directory-category:games", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Games"),
      slug: "games",
      name: "Games",
      display_order: 4
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"directory-category:weird-wonderful", "1"} do
  GottaCc.Repo.insert!(
    %Category{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Category@Weird & Wonderful"),
      slug: "weird-wonderful",
      name: "Weird & Wonderful",
      display_order: 5
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

