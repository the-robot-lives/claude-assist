alias GottaCc.Schema.Directory.Site
# Directory sites (changelog 025), converted from .design/curation/sites-human-web.yaml.
# overall_score + search_vector are GENERATED columns (not set here). Idempotent by id.

category_ids = %{
  "Technology" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Technology"),
  "Culture" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Culture"),
  "Science" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Science"),
  "Making & Crafts" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Making & Crafts"),
  "Games" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Games"),
  "Weird & Wonderful" => UUID.uuid5(:oid, "GottaCc.Directory.Category@Weird & Wonderful"),
}

seed "directory-site:usesthis" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@usesthis"),
      slug: "usesthis",
      name: "Uses This",
      url: "https://usesthis.com",
      domain: "usesthis.com",
      summary: "Nerdy interviews asking people from all walks of life what hardware and software get the job done.",
      category_id: category_ids["Technology"],
      tags: ["interviews", "tools", "hardware", "software"],
      originality: 88,
      human_authorship: 95,
      depth: 82,
      freshness: 65,
      design_quality: 76,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lwn" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lwn"),
      slug: "lwn",
      name: "LWN.net",
      url: "https://lwn.net",
      domain: "lwn.net",
      summary: "Reader-supported deep journalism from inside the Linux and free-software development communities.",
      category_id: category_ids["Technology"],
      tags: ["linux", "kernel", "free-software", "journalism"],
      originality: 72,
      human_authorship: 90,
      depth: 95,
      freshness: 92,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:hackaday" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@hackaday"),
      slug: "hackaday",
      name: "Hackaday",
      url: "https://hackaday.com",
      domain: "hackaday.com",
      summary: "Daily feed of obsessive hardware hacks, repair write-ups, and open-source engineering deep dives.",
      category_id: category_ids["Technology"],
      tags: ["hardware", "hacks", "electronics", "making"],
      originality: 78,
      human_authorship: 85,
      depth: 80,
      freshness: 95,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lemire" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lemire"),
      slug: "lemire",
      name: "Daniel Lemire",
      url: "https://lemire.me/blog/",
      domain: "lemire.me",
      summary: "A top-2% computer scientist writes weekly about software performance, parsing, and CPU internals.",
      category_id: category_ids["Technology"],
      tags: ["performance", "programming", "computer-science", "research"],
      originality: 75,
      human_authorship: 92,
      depth: 88,
      freshness: 90,
      design_quality: 60,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:benborgers" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@benborgers"),
      slug: "benborgers",
      name: "Ben Borgers",
      url: "https://benborgers.com",
      domain: "benborgers.com",
      summary: "A software engineer's hand-built blog on web craft, habits, and the quiet pleasure of shipping small things.",
      category_id: category_ids["Technology"],
      tags: ["blog", "web", "eleventy", "writing"],
      originality: 70,
      human_authorship: 90,
      depth: 72,
      freshness: 80,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:daringfireball" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@daringfireball"),
      slug: "daringfireball",
      name: "Daring Fireball",
      url: "https://daringfireball.net",
      domain: "daringfireball.net",
      summary: "John Gruber's two-decade indie blog on Apple, design, and the web — sponsored, never sold.",
      category_id: category_ids["Technology"],
      tags: ["apple", "blog", "opinion", "links"],
      originality: 70,
      human_authorship: 90,
      depth: 85,
      freshness: 95,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:tildes" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@tildes"),
      slug: "tildes",
      name: "Tildes",
      url: "https://tildes.net",
      domain: "tildes.net",
      summary: "An invite-only, non-profit, ad-free discussion site aiming for higher signal than Reddit.",
      category_id: category_ids["Technology"],
      tags: ["community", "discussion", "forum", "non-profit"],
      originality: 72,
      human_authorship: 88,
      depth: 75,
      freshness: 90,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ycombinator" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ycombinator"),
      slug: "ycombinator",
      name: "Hacker News",
      url: "https://news.ycombinator.com",
      domain: "news.ycombinator.com",
      summary: "A gloriously plain link board where builders argue about everything, six tabs deep.",
      category_id: category_ids["Technology"],
      tags: ["news", "discussion", "startups", "links"],
      originality: 65,
      human_authorship: 75,
      depth: 85,
      freshness: 95,
      design_quality: 45,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lobste" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lobste"),
      slug: "lobste",
      name: "Lobsters",
      url: "https://lobste.rs",
      domain: "lobste.rs",
      summary: "Invite-only link board for thoughtful computing discussion, free of the HN rat-race.",
      category_id: category_ids["Technology"],
      tags: ["links", "discussion", "programming", "community"],
      originality: 70,
      human_authorship: 85,
      depth: 80,
      freshness: 88,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:jvns" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@jvns"),
      slug: "jvns",
      name: "Julia Evans",
      url: "https://jvns.ca",
      domain: "jvns.ca",
      summary: "Hand-drawn zines and lucid write-ups that make kernels, DNS, and git feel approachable.",
      category_id: category_ids["Technology"],
      tags: ["systems", "zines", "debugging", "explanations"],
      originality: 90,
      human_authorship: 95,
      depth: 88,
      freshness: 90,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:drewdevault" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@drewdevault"),
      slug: "drewdevault",
      name: "Drew DeVault",
      url: "https://drewdevault.com",
      domain: "drewdevault.com",
      summary: "Opinionated deep dives from a free-software engineer building sr.ht, Hare, and Helios.",
      category_id: category_ids["Technology"],
      tags: ["free-software", "systems", "opinion", "blog"],
      originality: 78,
      human_authorship: 90,
      depth: 82,
      freshness: 85,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ploum" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ploum"),
      slug: "ploum",
      name: "Ploum.net",
      url: "https://ploum.net",
      domain: "ploum.net",
      summary: "A Franco-Belgian engineer-novelist's long-running bilingual blog on libre software and futures.",
      category_id: category_ids["Technology"],
      tags: ["blog", "libre-software", "scifi", "writing"],
      originality: 80,
      human_authorship: 92,
      depth: 78,
      freshness: 85,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:musicforprogramming" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@musicforprogramming"),
      slug: "musicforprogramming",
      name: "musicForProgramming",
      url: "https://musicforprogramming.net",
      domain: "musicforprogramming.net",
      summary: "Curated atmospheric mixes by Datassette, designed to disappear while you work.",
      category_id: category_ids["Technology"],
      tags: ["music", "mixes", "focus", "ambient"],
      originality: 85,
      human_authorship: 88,
      depth: 75,
      freshness: 70,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:tilde" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@tilde"),
      slug: "tilde",
      name: "tilde.club",
      url: "https://tilde.club",
      domain: "tilde.club",
      summary: "The original tilde — a shared Unix box where strangers hand-code homepages in plain HTML.",
      category_id: category_ids["Technology"],
      tags: ["tilde", "shell", "community", "small-web"],
      originality: 90,
      human_authorship: 92,
      depth: 70,
      freshness: 80,
      design_quality: 50,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:tilde-2" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@tilde-2"),
      slug: "tilde-2",
      name: "tilde.town",
      url: "https://tilde.town",
      domain: "tilde.town",
      summary: "An intentional small community of ~3000 users making art and learning Linux on a shared server.",
      category_id: category_ids["Technology"],
      tags: ["tilde", "community", "art", "small-web"],
      originality: 85,
      human_authorship: 92,
      depth: 72,
      freshness: 85,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:32bit" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@32bit"),
      slug: "32bit",
      name: "32-Bit Cafe",
      url: "https://32bit.cafe",
      domain: "32bit.cafe",
      summary: "A forum of hobbyists helping each other build personal websites for self-expression.",
      category_id: category_ids["Technology"],
      tags: ["small-web", "community", "html", "resources"],
      originality: 78,
      human_authorship: 90,
      depth: 70,
      freshness: 88,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:neocities" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@neocities"),
      slug: "neocities",
      name: "Neocities",
      url: "https://neocities.org",
      domain: "neocities.org",
      summary: "A nonprofit GeoCities heir where anyone can spin up a hand-coded homepage, zero ads.",
      category_id: category_ids["Technology"],
      tags: ["hosting", "homepages", "free", "small-web"],
      originality: 80,
      human_authorship: 85,
      depth: 70,
      freshness: 90,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:omg" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@omg"),
      slug: "omg",
      name: "omg.lol",
      url: "https://omg.lol",
      domain: "omg.lol",
      summary: "A $20/yr club giving you a lovable profile page, email aliases, and blog on a memorable domain.",
      category_id: category_ids["Technology"],
      tags: ["homepage", "email", "indie-web", "community"],
      originality: 88,
      human_authorship: 90,
      depth: 65,
      freshness: 90,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:status" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@status"),
      slug: "status",
      name: "status.cafe",
      url: "https://status.cafe",
      domain: "status.cafe",
      summary: "A tiny indie-web service for posting what you're up to and reading others' short updates.",
      category_id: category_ids["Technology"],
      tags: ["status", "microblog", "indie-web", "neocities"],
      originality: 82,
      human_authorship: 88,
      depth: 55,
      freshness: 80,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:indieweb" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@indieweb"),
      slug: "indieweb",
      name: "IndieWeb",
      url: "https://indieweb.org",
      domain: "indieweb.org",
      summary: "A community and wiki dedicated to owning your content on your own website.",
      category_id: category_ids["Technology"],
      tags: ["standards", "personal-site", "federation", "wiki"],
      originality: 80,
      human_authorship: 88,
      depth: 85,
      freshness: 85,
      design_quality: 60,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:pleroma" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@pleroma"),
      slug: "pleroma",
      name: "Pleroma",
      url: "https://pleroma.social",
      domain: "pleroma.social",
      summary: "A lightweight federated social server one person can run, built in Elixir.",
      category_id: category_ids["Technology"],
      tags: ["federation", "mastodon", "activitypub", "self-host"],
      originality: 72,
      human_authorship: 85,
      depth: 75,
      freshness: 75,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:are" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@are"),
      slug: "are",
      name: "Are.na",
      url: "https://www.are.na",
      domain: "are.na",
      summary: "A slow, ad-free research tool for collecting ideas into public and private channels.",
      category_id: category_ids["Technology"],
      tags: ["research", "bookmarking", "moodboard", "collaborative"],
      originality: 82,
      human_authorship: 78,
      depth: 80,
      freshness: 85,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:tynan" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@tynan"),
      slug: "tynan",
      name: "Tynan",
      url: "https://tynan.com",
      domain: "tynan.com",
      summary: "A nomad who built a cruise-booking site blogs about habits, poker, and freedom for 15+ years.",
      category_id: category_ids["Technology"],
      tags: ["blog", "travel", "lifestyle", "writing"],
      originality: 75,
      human_authorship: 92,
      depth: 80,
      freshness: 70,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:cabel" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@cabel"),
      slug: "cabel",
      name: "Cabel Sasser",
      url: "https://cabel.com",
      domain: "cabel.com",
      summary: "Panic co-founder's blog mixing Playdate lore, Portland tech stories, and annual snack reviews.",
      category_id: category_ids["Technology"],
      tags: ["blog", "panic", "playdate", "snacks"],
      originality: 82,
      human_authorship: 92,
      depth: 78,
      freshness: 85,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lowtechmagazine" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lowtechmagazine"),
      slug: "lowtechmagazine",
      name: "solar.lowtechmagazine",
      url: "https://solar.lowtechmagazine.com",
      domain: "solar.lowtechmagazine.com",
      summary: "A solar-powered, battery-backed publication that goes dark when the sun doesn't shine.",
      category_id: category_ids["Technology"],
      tags: ["lowtech", "solar", "sustainability", "design"],
      originality: 95,
      human_authorship: 88,
      depth: 90,
      freshness: 80,
      design_quality: 85,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:100r" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@100r"),
      slug: "100r",
      name: "Hundred Rabbits",
      url: "https://100r.co",
      domain: "100r.co",
      summary: "Two artists live aboard a sailboat, building tiny resilient tools like Orca and Left.",
      category_id: category_ids["Technology"],
      tags: ["lowtech", "sailing", "software", "art"],
      originality: 92,
      human_authorship: 95,
      depth: 85,
      freshness: 80,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:kottke" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@kottke"),
      slug: "kottke",
      name: "kottke.org",
      url: "https://kottke.org",
      domain: "kottke.org",
      summary: "Jason Kottke's one-man link blog since 1998 — the patron saint of indie web curators.",
      category_id: category_ids["Culture"],
      tags: ["links", "design", "film", "culture"],
      originality: 75,
      human_authorship: 92,
      depth: 90,
      freshness: 92,
      design_quality: 80,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:craigmod" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@craigmod"),
      slug: "craigmod",
      name: "Craig Mod",
      url: "https://craigmod.com",
      domain: "craigmod.com",
      summary: "A writer-photographer's luminous essays on books, walking, and the edges of rural Japan.",
      category_id: category_ids["Culture"],
      tags: ["essays", "japan", "walking", "books"],
      originality: 88,
      human_authorship: 95,
      depth: 92,
      freshness: 80,
      design_quality: 90,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:waxy" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@waxy"),
      slug: "waxy",
      name: "Waxy",
      url: "https://waxy.org",
      domain: "waxy.org",
      summary: "Andy Baio's 20-year sandbox of linkblogging, KS archived, and online-culture forensics.",
      category_id: category_ids["Culture"],
      tags: ["internet-culture", "links", "essays", "mischief"],
      originality: 82,
      human_authorship: 92,
      depth: 85,
      freshness: 70,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:robinsloan" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@robinsloan"),
      slug: "robinsloan",
      name: "Robin Sloan",
      url: "https://robinsloan.com",
      domain: "robinsloan.com",
      summary: "A novelist's lab for incubating small fiction, wine-fueled experiments, and calmer feeds.",
      category_id: category_ids["Culture"],
      tags: ["writing", "fiction", "experiments", "newsletters"],
      originality: 90,
      human_authorship: 92,
      depth: 82,
      freshness: 78,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:jennyodell" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@jennyodell"),
      slug: "jennyodell",
      name: "Jenny Odell",
      url: "https://jennyodell.com",
      domain: "jennyodell.com",
      summary: "The artist behind 'How to Do Nothing' publishes research on attention, ecology, and refusal.",
      category_id: category_ids["Culture"],
      tags: ["art", "attention", "essays", "ecology"],
      originality: 88,
      human_authorship: 90,
      depth: 82,
      freshness: 65,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:meredithwhittaker" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@meredithwhittaker"),
      slug: "meredithwhittaker",
      name: "Meredith Whittaker",
      url: "https://meredithwhittaker.net",
      domain: "meredithwhittaker.net",
      summary: "Signal Foundation president's talks and essays on data, labor, and resisting surveillance.",
      category_id: category_ids["Culture"],
      tags: ["privacy", "ai", "essays", "talks"],
      originality: 78,
      human_authorship: 90,
      depth: 80,
      freshness: 70,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:maggieappleton" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@maggieappleton"),
      slug: "maggieappleton",
      name: "Maggie Appleton",
      url: "https://maggieappleton.com",
      domain: "maggieappleton.com",
      summary: "An illustrator-anthropologist's digital garden of essays, sketches, and UX pattern libraries.",
      category_id: category_ids["Culture"],
      tags: ["digital-gardening", "illustration", "essays", "ux"],
      originality: 88,
      human_authorship: 92,
      depth: 85,
      freshness: 80,
      design_quality: 90,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:andymatuschak" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@andymatuschak"),
      slug: "andymatuschak",
      name: "Andy Matuschak",
      url: "https://andymatuschak.org",
      domain: "andymatuschak.org",
      summary: "A learning researcher's working notes on memory, mastery, and the craft of true understanding.",
      category_id: category_ids["Culture"],
      tags: ["learning", "spaced-repetition", "notes", "research"],
      originality: 85,
      human_authorship: 90,
      depth: 88,
      freshness: 65,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:gwern" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@gwern"),
      slug: "gwern",
      name: "Gwern.net",
      url: "https://gwern.net",
      domain: "gwern.net",
      summary: "A pseudonymous polymath's deeply linked essays on AI, nootropics, and the darknet, footnoted to the hilt.",
      category_id: category_ids["Culture"],
      tags: ["essays", "research", "darknet", "statistics"],
      originality: 92,
      human_authorship: 88,
      depth: 95,
      freshness: 78,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:paulgraham" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@paulgraham"),
      slug: "paulgraham",
      name: "Paul Graham",
      url: "https://paulgraham.com",
      domain: "paulgraham.com",
      summary: "Y Combinator co-founder's essay archive on building, thinking, and cities — the indie classic.",
      category_id: category_ids["Culture"],
      tags: ["essays", "startups", "lisp", "yc"],
      originality: 75,
      human_authorship: 88,
      depth: 90,
      freshness: 60,
      design_quality: 50,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:patrickcollison" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@patrickcollison"),
      slug: "patrickcollison",
      name: "Patrick Collison",
      url: "https://patrickcollison.com",
      domain: "patrickcollison.com",
      summary: "Stripe CEO's personal site of reading lists, fast-company chronologies, and quiet essays.",
      category_id: category_ids["Culture"],
      tags: ["essays", "books", "ireland", "tech"],
      originality: 70,
      human_authorship: 88,
      depth: 82,
      freshness: 70,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:pinboard" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@pinboard"),
      slug: "pinboard",
      name: "Maciej Cegłowski",
      url: "https://pinboard.in/u/maciej",
      domain: "pinboard.in",
      summary: "Pinboard founder's heartfelt talks on the deep internet, the Hudson River School, and spiders.",
      category_id: category_ids["Culture"],
      tags: ["talks", "travel", "bookmarks", "misc"],
      originality: 88,
      human_authorship: 90,
      depth: 82,
      freshness: 60,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:bloomberg" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@bloomberg"),
      slug: "bloomberg",
      name: "Matt Levine",
      url: "https://www.bloomberg.com/opinion/authors/ARbTQlRRIgEY/matthew-levine",
      domain: "bloomberg.com",
      summary: "Money Stuff — the one finance newsletter that makes Wall Street funny and understandable.",
      category_id: category_ids["Culture"],
      tags: ["finance", "newsletter", "humor", "analysis"],
      originality: 82,
      human_authorship: 90,
      depth: 90,
      freshness: 95,
      design_quality: 60,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:stratechery" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@stratechery"),
      slug: "stratechery",
      name: "Stratechery",
      url: "https://stratechery.com",
      domain: "stratechery.com",
      summary: "Ben Thompson's one-man tech-strategy newsletter that rewrote the analyst business model.",
      category_id: category_ids["Culture"],
      tags: ["business", "strategy", "essays", "tech"],
      originality: 85,
      human_authorship: 88,
      depth: 88,
      freshness: 95,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:honest-broker" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@honest-broker"),
      slug: "honest-broker",
      name: "Ted Gioia",
      url: "https://www.honest-broker.com",
      domain: "honest-broker.com",
      summary: "A music historian's frank substack on the cultural economics of songs and the art-stealing algorithm.",
      category_id: category_ids["Culture"],
      tags: ["music", "criticism", "essays", "books"],
      originality: 85,
      human_authorship: 90,
      depth: 88,
      freshness: 90,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ribbonfarm" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ribbonfarm"),
      slug: "ribbonfarm",
      name: "Ribbonfarm",
      url: "https://ribbonfarm.com",
      domain: "ribbonfarm.com",
      summary: "Venkatesh Rao's long-running series on weird philosophy, temenos, and the domestic scene.",
      category_id: category_ids["Culture"],
      tags: ["essays", "philosophy", "longform", "weird"],
      originality: 90,
      human_authorship: 88,
      depth: 88,
      freshness: 65,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:pudding" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@pudding"),
      slug: "pudding",
      name: "The Pudding",
      url: "https://pudding.cool",
      domain: "pudding.cool",
      summary: "A small studio publishing visual essays about culture, from pop charts to slang dictionaries.",
      category_id: category_ids["Culture"],
      tags: ["data", "essays", "visual", "journalism"],
      originality: 88,
      human_authorship: 85,
      depth: 82,
      freshness: 85,
      design_quality: 92,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:are-2" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@are-2"),
      slug: "are-2",
      name: "Are.na Editorial",
      url: "https://www.are.na/editorial",
      domain: "are.na",
      summary: "Are.na's editorial blog of slow reads and channel roundups from the platform's research community.",
      category_id: category_ids["Culture"],
      tags: ["research", "curation", "blog", "design"],
      originality: 78,
      human_authorship: 82,
      depth: 78,
      freshness: 75,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:thebrowser" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@thebrowser"),
      slug: "thebrowser",
      name: "The Browser",
      url: "https://thebrowser.com",
      domain: "thebrowser.com",
      summary: "A daily human-curated email of the five best magazine pieces on the internet.",
      category_id: category_ids["Culture"],
      tags: ["curation", "reading", "links", "paid"],
      originality: 65,
      human_authorship: 85,
      depth: 85,
      freshness: 92,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:longreads" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@longreads"),
      slug: "longreads",
      name: "Long Reads",
      url: "https://longreads.com",
      domain: "longreads.com",
      summary: "The best long-form nonfiction of the week, curated by editors who actually read it all.",
      category_id: category_ids["Culture"],
      tags: ["longform", "curation", "nonfiction", "essays"],
      originality: 68,
      human_authorship: 80,
      depth: 88,
      freshness: 92,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:niemanlab" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@niemanlab"),
      slug: "niemanlab",
      name: "Nieman Lab",
      url: "https://www.niemanlab.org",
      domain: "niemanlab.org",
      summary: "Harvard's lab tracking the future of journalism, from indie newsletters to AI slop.",
      category_id: category_ids["Culture"],
      tags: ["journalism", "media", "research", "essays"],
      originality: 72,
      human_authorship: 82,
      depth: 85,
      freshness: 90,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:3quarksdaily" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@3quarksdaily"),
      slug: "3quarksdaily",
      name: "3 Quarks Daily",
      url: "https://3quarksdaily.com",
      domain: "3quarksdaily.com",
      summary: "An independent magazine aggregating and writing essays across science, art, and politics.",
      category_id: category_ids["Culture"],
      tags: ["essays", "philosophy", "science", "curation"],
      originality: 75,
      human_authorship: 80,
      depth: 88,
      freshness: 90,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:thenewinquiry" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@thenewinquiry"),
      slug: "thenewinquiry",
      name: "The New Inquiry",
      url: "https://thenewinquiry.com",
      domain: "thenewinquiry.com",
      summary: "An indie magazine of cultural criticism that treats the internet as a serious subject.",
      category_id: category_ids["Culture"],
      tags: ["criticism", "culture", "essays", "indie"],
      originality: 85,
      human_authorship: 80,
      depth: 85,
      freshness: 70,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:reallifemag" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@reallifemag"),
      slug: "reallifemag",
      name: "Real Life",
      url: "https://reallifemag.com",
      domain: "reallifemag.com",
      summary: "A magazine of original essays about the texture of living with screens.",
      category_id: category_ids["Culture"],
      tags: ["essays", "technology", "criticism", "culture"],
      originality: 82,
      human_authorship: 82,
      depth: 85,
      freshness: 75,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:clivethompson" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@clivethompson"),
      slug: "clivethompson",
      name: "Clive Thompson",
      url: "https://clivethompson.net",
      domain: "clivethompson.net",
      summary: "A tech journalist's personal blog of reporting outtakes on coding, tools, and everyday life.",
      category_id: category_ids["Culture"],
      tags: ["journalism", "technology", "writing", "blog"],
      originality: 70,
      human_authorship: 88,
      depth: 80,
      freshness: 70,
      design_quality: 62,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:anildash" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@anildash"),
      slug: "anildash",
      name: "Anil Dash",
      url: "https://anildash.com",
      domain: "anildash.com",
      summary: "A tech activist's essays on the ethical web, platform power, and making software humane.",
      category_id: category_ids["Culture"],
      tags: ["essays", "tech", "ethics", "culture"],
      originality: 72,
      human_authorship: 88,
      depth: 80,
      freshness: 65,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:interconnected" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@interconnected"),
      slug: "interconnected",
      name: "Matt Webb",
      url: "https://interconnected.org",
      domain: "interconnected.org",
      summary: "A designer-philosopher's daily blog on AI assistants, haiku computers, and botany.",
      category_id: category_ids["Culture"],
      tags: ["blog", "ai", "design", "experiments"],
      originality: 88,
      human_authorship: 92,
      depth: 82,
      freshness: 88,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:quantamagazine" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@quantamagazine"),
      slug: "quantamagazine",
      name: "Quanta Magazine",
      url: "https://www.quantamagazine.org",
      domain: "quantamagazine.org",
      summary: "Simons Foundation-backed, editorially independent deep math and science journalism.",
      category_id: category_ids["Science"],
      tags: ["math", "physics", "biology", "journalism"],
      originality: 82,
      human_authorship: 80,
      depth: 92,
      freshness: 92,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:nautil" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@nautil"),
      slug: "nautil",
      name: "Nautilus",
      url: "https://nautil.us",
      domain: "nautil.us",
      summary: "A different kind of science magazine, exploring how science ripples through our lives.",
      category_id: category_ids["Science"],
      tags: ["science", "culture", "longform", "thematic"],
      originality: 80,
      human_authorship: 80,
      depth: 85,
      freshness: 80,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:jstor" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@jstor"),
      slug: "jstor",
      name: "JSTOR Daily",
      url: "https://daily.jstor.org",
      domain: "daily.jstor.org",
      summary: "Scholarly context for news, with free links into the journals behind the JSTOR paywall.",
      category_id: category_ids["Science"],
      tags: ["research", "humanities", "history", "free"],
      originality: 75,
      human_authorship: 80,
      depth: 88,
      freshness: 90,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:nasa" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@nasa"),
      slug: "nasa",
      name: "APOD",
      url: "https://apod.nasa.gov/apod/astropix.html",
      domain: "apod.nasa.gov",
      summary: "Each day, one stunning astronomical image with a paragraph by a professional astronomer.",
      category_id: category_ids["Science"],
      tags: ["astronomy", "photography", "daily", "space"],
      originality: 70,
      human_authorship: 85,
      depth: 75,
      freshness: 95,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:astrobio" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@astrobio"),
      slug: "astrobio",
      name: "Astrobiology Magazine",
      url: "https://www.astrobio.net",
      domain: "astrobio.net",
      summary: "Reporting on the search for life in the universe, from Mars rovers to extremophiles.",
      category_id: category_ids["Science"],
      tags: ["astrobiology", "space", "life", "news"],
      originality: 72,
      human_authorship: 75,
      depth: 80,
      freshness: 70,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:fnal" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@fnal"),
      slug: "fnal",
      name: "Fermilab Today",
      url: "https://news.fnal.gov",
      domain: "news.fnal.gov",
      summary: "First-hand reporting from a national particle physics lab, straight from the experiment floor.",
      category_id: category_ids["Science"],
      tags: ["physics", "particle", "research", "news"],
      originality: 70,
      human_authorship: 80,
      depth: 82,
      freshness: 85,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:sciencenews" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@sciencenews"),
      slug: "sciencenews",
      name: "Science News",
      url: "https://www.sciencenews.org",
      domain: "sciencenews.org",
      summary: "A century-old nonprofit newsroom covering all sciences for a general audience.",
      category_id: category_ids["Science"],
      tags: ["science", "news", "research", "journalism"],
      originality: 68,
      human_authorship: 80,
      depth: 85,
      freshness: 92,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:wordpress" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@wordpress"),
      slug: "wordpress",
      name: "In the Dark",
      url: "https://telescoper.wordpress.com",
      domain: "telescoper.wordpress.com",
      summary: "A cosmologist's personal blog on the universe, academic life, and music.",
      category_id: category_ids["Science"],
      tags: ["astronomy", "cosmology", "blog", "academic"],
      originality: 72,
      human_authorship: 88,
      depth: 80,
      freshness: 80,
      design_quality: 58,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:scienceblogs" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@scienceblogs"),
      slug: "scienceblogs",
      name: "Dynamics of Cats",
      url: "https://scienceblogs.com/dynamics-of-cats",
      domain: "scienceblogs.com",
      summary: "An astrophysicist's profane, witty, deep blog on telescopes, grants, and the universe.",
      category_id: category_ids["Science"],
      tags: ["astronomy", "physics", "blog", "opinion"],
      originality: 80,
      human_authorship: 85,
      depth: 78,
      freshness: 55,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:columbia" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@columbia"),
      slug: "columbia",
      name: "Not Even Wrong",
      url: "https://www.math.columbia.edu/~woit/wordpress",
      domain: "math.columbia.edu",
      summary: "Peter Woit's long-running Columbia-hosted blog critiquing string theory and covering HEP.",
      category_id: category_ids["Science"],
      tags: ["physics", "math", "string-theory", "criticism"],
      originality: 78,
      human_authorship: 90,
      depth: 88,
      freshness: 75,
      design_quality: 55,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:blogspot" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@blogspot"),
      slug: "blogspot",
      name: "Dorothy Bishop's Blog",
      url: "https://deevybee.blogspot.com",
      domain: "deevybee.blogspot.com",
      summary: "An Oxford psychologist's relentless blog on research methods, open science, and integrity.",
      category_id: category_ids["Science"],
      tags: ["psychology", "research-integrity", "methods", "academic"],
      originality: 78,
      human_authorship: 90,
      depth: 85,
      freshness: 70,
      design_quality: 58,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:discovermagazine" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@discovermagazine"),
      slug: "discovermagazine",
      name: "Neuroskeptic",
      url: "https://blogs.discovermagazine.com/neuroskeptic",
      domain: "blogs.discovermagazine.com",
      summary: "A pseudonymous neuroscientist's clear-eyed skepticism about their own field's headline claims.",
      category_id: category_ids["Science"],
      tags: ["neuroscience", "skepticism", "methods", "blog"],
      originality: 80,
      human_authorship: 85,
      depth: 85,
      freshness: 65,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:royalsocietypublishing" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@royalsocietypublishing"),
      slug: "royalsocietypublishing",
      name: "Royal Society Publishing",
      url: "https://royalsocietypublishing.org",
      domain: "royalsocietypublishing.org",
      summary: "The world's oldest scientific society's journals — including fully open archives going back to 1665.",
      category_id: category_ids["Science"],
      tags: ["journals", "papers", "history", "open-access"],
      originality: 60,
      human_authorship: 75,
      depth: 92,
      freshness: 90,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:arxiv" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@arxiv"),
      slug: "arxiv",
      name: "arXiv",
      url: "https://arxiv.org",
      domain: "arxiv.org",
      summary: "The preprint server that moved physics, math, and CS into the open-access era.",
      category_id: category_ids["Science"],
      tags: ["preprints", "physics", "math", "cs"],
      originality: 78,
      human_authorship: 70,
      depth: 95,
      freshness: 95,
      design_quality: 50,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:syfy" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@syfy"),
      slug: "syfy",
      name: "Phil Plait",
      url: "https://www.syfy.com/syfy-wire/bad-astronomy",
      domain: "syfy.com",
      summary: "The Bad Astronomer's clear, enthusiastic articles on the cosmos and the bad science about it.",
      category_id: category_ids["Science"],
      tags: ["astronomy", "skepticism", "writing", "outreach"],
      originality: 68,
      human_authorship: 85,
      depth: 80,
      freshness: 70,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:edwardyong" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@edwardyong"),
      slug: "edwardyong",
      name: "Ed Yong",
      url: "https://edwardyong.com",
      domain: "edwardyong.com",
      summary: "A Pulitzer-winning science writer's personal site of essays on animals, microbes, and humans.",
      category_id: category_ids["Science"],
      tags: ["biology", "journalism", "writing", "essays"],
      originality: 75,
      human_authorship: 88,
      depth: 85,
      freshness: 55,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:carlzimmer" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@carlzimmer"),
      slug: "carlzimmer",
      name: "Carl Zimmer",
      url: "https://carlzimmer.com",
      domain: "carlzimmer.com",
      summary: "A leading science journalist's site of articles and books on genes, brains, and evolution.",
      category_id: category_ids["Science"],
      tags: ["biology", "journalism", "books", "essays"],
      originality: 72,
      human_authorship: 88,
      depth: 85,
      freshness: 70,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:kalzumeus" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@kalzumeus"),
      slug: "kalzumeus",
      name: "Kalzumeus",
      url: "https://www.kalzumeus.com",
      domain: "kalzumeus.com",
      summary: "Patrick McKenzie's long-form blog on software businesses, engineering careers, and the Pacific.",
      category_id: category_ids["Science"],
      tags: ["blog", "tech", "business", "japan"],
      originality: 75,
      human_authorship: 90,
      depth: 88,
      freshness: 70,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:spaceweather" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@spaceweather"),
      slug: "spaceweather",
      name: "Spaceweather",
      url: "https://spaceweather.com",
      domain: "spaceweather.com",
      summary: "A hobbyist-grade daily tracker of solar flares, auroras, and near-Earth asteroids.",
      category_id: category_ids["Science"],
      tags: ["solar", "aurora", "space", "news"],
      originality: 85,
      human_authorship: 85,
      depth: 78,
      freshness: 92,
      design_quality: 50,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ourworldindata" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ourworldindata"),
      slug: "ourworldindata",
      name: "Our World in Data",
      url: "https://ourworldindata.org",
      domain: "ourworldindata.org",
      summary: "Oxford researchers publishing the big charts that put global problems in perspective.",
      category_id: category_ids["Science"],
      tags: ["data", "charts", "research", "global"],
      originality: 80,
      human_authorship: 78,
      depth: 92,
      freshness: 90,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:waitbutwhy" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@waitbutwhy"),
      slug: "waitbutwhy",
      name: "Wait But Why",
      url: "https://waitbutwhy.com",
      domain: "waitbutwhy.com",
      summary: "Tim Urban's wildly illustrated deep dives into AI, the Fermi paradox, and your procrastination.",
      category_id: category_ids["Science"],
      tags: ["longform", "stick-figures", "procrastination", "explainers"],
      originality: 90,
      human_authorship: 88,
      depth: 88,
      freshness: 45,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:instructables" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@instructables"),
      slug: "instructables",
      name: "Instructables",
      url: "https://www.instructables.com",
      domain: "instructables.com",
      summary: "A community of makers sharing step-by-step builds for everything from kites to combat robots.",
      category_id: category_ids["Making & Crafts"],
      tags: ["diy", "projects", "community", "step-by-step"],
      originality: 70,
      human_authorship: 78,
      depth: 90,
      freshness: 90,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:hackster" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@hackster"),
      slug: "hackster",
      name: "Hackster.io",
      url: "https://www.hackster.io",
      domain: "hackster.io",
      summary: "A community of hardware hackers documenting builds from blinking LEDs to weather stations.",
      category_id: category_ids["Making & Crafts"],
      tags: ["hardware", "electronics", "arduino", "community"],
      originality: 72,
      human_authorship: 78,
      depth: 85,
      freshness: 90,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:wizardzines" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@wizardzines"),
      slug: "wizardzines",
      name: "Julia Evans Zines",
      url: "https://wizardzines.com",
      domain: "wizardzines.com",
      summary: "Buy Julia Evans's hand-drawn zines on debugging, DNS, and how git really works.",
      category_id: category_ids["Making & Crafts"],
      tags: ["zines", "programming", "art", "explanations"],
      originality: 92,
      human_authorship: 95,
      depth: 85,
      freshness: 75,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ravelry" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ravelry"),
      slug: "ravelry",
      name: "Ravelry",
      url: "https://www.ravelry.com",
      domain: "ravelry.com",
      summary: "The cozy, female-led pattern library and community for knitters and crocheters worldwide.",
      category_id: category_ids["Making & Crafts"],
      tags: ["knitting", "crochet", "patterns", "community"],
      originality: 80,
      human_authorship: 85,
      depth: 92,
      freshness: 88,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:adafruit" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@adafruit"),
      slug: "adafruit",
      name: "Adafruit",
      url: "https://blog.adafruit.com",
      domain: "blog.adafruit.com",
      summary: "Lady Ada's open-source hardware company blog: project tutorials, new boards, and maker news.",
      category_id: category_ids["Making & Crafts"],
      tags: ["electronics", "wearables", "maker", "open-source"],
      originality: 75,
      human_authorship: 82,
      depth: 85,
      freshness: 92,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:textile" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@textile"),
      slug: "textile",
      name: "textile",
      url: "https://textile.io",
      domain: "textile.io",
      summary: "A small studio's blog on weaving, slow making, and the politics of cloth.",
      category_id: category_ids["Making & Crafts"],
      tags: ["weaving", "textiles", "craft", "blog"],
      originality: 82,
      human_authorship: 85,
      depth: 75,
      freshness: 60,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:hackclub" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@hackclub"),
      slug: "hackclub",
      name: "Hack Club",
      url: "https://hackclub.com",
      domain: "hackclub.com",
      summary: "A nonprofit by-and-for teenagers building real open-source projects, not just tutorials.",
      category_id: category_ids["Making & Crafts"],
      tags: ["teens", "coding", "open-source", "nonprofit"],
      originality: 85,
      human_authorship: 90,
      depth: 78,
      freshness: 90,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:atlasobscura" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@atlasobscura"),
      slug: "atlasobscura",
      name: "Atlas Obscura",
      url: "https://www.atlasobscura.com",
      domain: "atlasobscura.com",
      summary: "A user-built catalog of the world's wondrous, curious, and overlooked places and recipes.",
      category_id: category_ids["Making & Crafts"],
      tags: ["places", "history", "food", "curiosities"],
      originality: 85,
      human_authorship: 78,
      depth: 88,
      freshness: 88,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:core77" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@core77"),
      slug: "core77",
      name: "Core77",
      url: "https://www.core77.com",
      domain: "core77.com",
      summary: "An independent site covering industrial design, DIY, and the craft of physical objects.",
      category_id: category_ids["Making & Crafts"],
      tags: ["industrial-design", "making", "blog", "community"],
      originality: 78,
      human_authorship: 80,
      depth: 85,
      freshness: 85,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:craftsmanship" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@craftsmanship"),
      slug: "craftsmanship",
      name: "The Craftsmanship Initiative",
      url: "https://craftsmanship.net",
      domain: "craftsmanship.net",
      summary: "Long-form profiles of artisans keeping traditional crafts alive, from kintsugi to boatbuilding.",
      category_id: category_ids["Making & Crafts"],
      tags: ["craft", "artisans", "profiles", "magazine"],
      originality: 85,
      human_authorship: 85,
      depth: 88,
      freshness: 65,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:makezine" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@makezine"),
      slug: "makezine",
      name: "Pratt",
      url: "https://makezine.com",
      domain: "makezine.com",
      summary: "Make: magazine's online home of DIY project tutorials, maker profiles, and skill builders.",
      category_id: category_ids["Making & Crafts"],
      tags: ["maker", "diy", "electronics", "magazine"],
      originality: 72,
      human_authorship: 78,
      depth: 85,
      freshness: 88,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:dangerousprototypes" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@dangerousprototypes"),
      slug: "dangerousprototypes",
      name: "Dangerous Prototypes",
      url: "https://dangerousprototypes.com",
      domain: "dangerousprototypes.com",
      summary: "A small open-hardware outfit's blog of weird boards, logic analyzers, and Bus Pirate lore.",
      category_id: category_ids["Making & Crafts"],
      tags: ["electronics", "open-hardware", "blog", "projects"],
      originality: 80,
      human_authorship: 85,
      depth: 78,
      freshness: 75,
      design_quality: 62,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:bunniestudios" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@bunniestudios"),
      slug: "bunniestudios",
      name: "Bunnie Studios",
      url: "https://www.bunniestudios.com",
      domain: "bunniestudios.com",
      summary: "Bunnie Huang's personal blog of hardware teardowns, supply-chain investigations, and Shenzhen trips.",
      category_id: category_ids["Making & Crafts"],
      tags: ["hardware", "hacking", "open-source", "research"],
      originality: 88,
      human_authorship: 92,
      depth: 88,
      freshness: 75,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:beckystern" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@beckystern"),
      slug: "beckystern",
      name: "Becky Stern",
      url: "https://beckystern.com",
      domain: "beckystern.com",
      summary: "A maker-artist's project blog of DIY wearables, fiber crafts, and playful electronics.",
      category_id: category_ids["Making & Crafts"],
      tags: ["wearables", "diy", "electronics", "art"],
      originality: 85,
      human_authorship: 92,
      depth: 78,
      freshness: 85,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:asherv" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@asherv"),
      slug: "asherv",
      name: "Asher Vollmer",
      url: "https://asherv.com",
      domain: "asherv.com",
      summary: "An indie game designer's personal blog of design notes, prototypes, and pencil puzzles.",
      category_id: category_ids["Making & Crafts"],
      tags: ["game-design", "making", "blog", "indie"],
      originality: 82,
      human_authorship: 88,
      depth: 75,
      freshness: 60,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:finehomebuilding" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@finehomebuilding"),
      slug: "finehomebuilding",
      name: "Spruce",
      url: "https://finehomebuilding.com",
      domain: "finehomebuilding.com",
      summary: "An indie publisher's deep how-to magazine for fine woodworking and home building.",
      category_id: category_ids["Making & Crafts"],
      tags: ["woodworking", "building", "how-to", "magazine"],
      originality: 65,
      human_authorship: 75,
      depth: 88,
      freshness: 85,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:sketchplanations" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@sketchplanations"),
      slug: "sketchplanations",
      name: "Sketchplanations",
      url: "https://sketchplanations.com",
      domain: "sketchplanations.com",
      summary: "A maker's weekly one-sketch explanations of big ideas, from attention residue to theoverview effect.",
      category_id: category_ids["Making & Crafts"],
      tags: ["illustration", "ideas", "one-sketch", "blog"],
      originality: 88,
      human_authorship: 90,
      depth: 72,
      freshness: 80,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:karenx" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@karenx"),
      slug: "karenx",
      name: "Karen Cheng",
      url: "https://www.karenx.com",
      domain: "karenx.com",
      summary: "A designer's personal site of playful experiments, learning-in-public, and tiny side projects.",
      category_id: category_ids["Making & Crafts"],
      tags: ["design", "experiments", "personal", "blog"],
      originality: 82,
      human_authorship: 90,
      depth: 72,
      freshness: 70,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:itch" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@itch"),
      slug: "itch",
      name: "itch.io",
      url: "https://itch.io",
      domain: "itch.io",
      summary: "The indie-first marketplace for small games, game jams, and the people who love both.",
      category_id: category_ids["Games"],
      tags: ["indie", "store", "jams", "community"],
      originality: 85,
      human_authorship: 85,
      depth: 92,
      freshness: 95,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:galaxy" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@galaxy"),
      slug: "galaxy",
      name: "Galaxy",
      url: "https://galaxy.click",
      domain: "galaxy.click",
      summary: "An ad-free, open-source hub for discovering and discussing incremental games.",
      category_id: category_ids["Games"],
      tags: ["incremental", "idle", "community", "open-source"],
      originality: 88,
      human_authorship: 85,
      depth: 78,
      freshness: 85,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:itch-2" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@itch-2"),
      slug: "itch-2",
      name: "Daniel Linssen",
      url: "https://managore.itch.io",
      domain: "managore.itch.io",
      summary: "A singular indie dev's itch page of mind-bending platformers and Ludum Dare experiments.",
      category_id: category_ids["Games"],
      tags: ["indie", "platformers", "game-jams", "personal"],
      originality: 92,
      human_authorship: 95,
      depth: 80,
      freshness: 78,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:neal" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@neal"),
      slug: "neal",
      name: "Neal.fun",
      url: "https://neal.fun",
      domain: "neal.fun",
      summary: "Neal Agarwal's addictive one-man collection of interactive toys — spend your Bill Gates fortune.",
      category_id: category_ids["Games"],
      tags: ["interactive", "experiments", "play", "weird"],
      originality: 95,
      human_authorship: 92,
      depth: 85,
      freshness: 85,
      design_quality: 90,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:ldjam" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@ldjam"),
      slug: "ldjam",
      name: "Ludum Dare",
      url: "https://ldjam.com",
      domain: "ldjam.com",
      summary: "The legendary weekend game jam where thousands of solo devs ship raw, weird, playable things.",
      category_id: category_ids["Games"],
      tags: ["game-jam", "community", "competition", "indie"],
      originality: 85,
      human_authorship: 90,
      depth: 85,
      freshness: 90,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:incrementaldb" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@incrementaldb"),
      slug: "incrementaldb",
      name: "IncrementalDB",
      url: "https://incrementaldb.com",
      domain: "incrementaldb.com",
      summary: "A fan-maintained database of every incremental and idle game worth playing.",
      category_id: category_ids["Games"],
      tags: ["incremental", "idle", "database", "community"],
      originality: 78,
      human_authorship: 85,
      depth: 82,
      freshness: 70,
      design_quality: 68,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:rockpapershotgun" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@rockpapershotgun"),
      slug: "rockpapershotgun",
      name: "RPS",
      url: "https://www.rockpapershotgun.com",
      domain: "rockpapershotgun.com",
      summary: "A PC gaming site that still writes about weird indies and text adventures alongside the AAAs.",
      category_id: category_ids["Games"],
      tags: ["pc-gaming", "indie", "reviews", "blog"],
      originality: 70,
      human_authorship: 78,
      depth: 88,
      freshness: 92,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:pixelprospector" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@pixelprospector"),
      slug: "pixelprospector",
      name: "Pixel Prospector",
      url: "https://www.pixelprospector.com",
      domain: "pixelprospector.com",
      summary: "A one-man indie game gold mine of curated lists, dev interviews, and hidden gems.",
      category_id: category_ids["Games"],
      tags: ["indie-games", "curation", "blog", "lists"],
      originality: 80,
      human_authorship: 90,
      depth: 85,
      freshness: 55,
      design_quality: 70,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:play" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@play"),
      slug: "play",
      name: "Playdate Catalog",
      url: "https://play.date/games",
      domain: "play.date",
      summary: "Panic's hand-curated catalog of tiny seasonal games for the yellow crank console.",
      category_id: category_ids["Games"],
      tags: ["playdate", "indie", "catalog", "hardware"],
      originality: 88,
      human_authorship: 85,
      depth: 75,
      freshness: 88,
      design_quality: 92,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lexaloffle" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lexaloffle"),
      slug: "lexaloffle",
      name: "Pico-8",
      url: "https://www.lexaloffle.com/pico-8.php",
      domain: "lexaloffle.com",
      summary: "A fantasy console for making tiny pixel games in 128x128, with a fervent indie community.",
      category_id: category_ids["Games"],
      tags: ["fantasy-console", "pixel-art", "lua", "community"],
      originality: 92,
      human_authorship: 85,
      depth: 85,
      freshness: 85,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:boardgamegeek" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@boardgamegeek"),
      slug: "boardgamegeek",
      name: "BoardGameGeek",
      url: "https://boardgamegeek.com",
      domain: "boardgamegeek.com",
      summary: "The community-built encyclopedia of every board game ever, with reviews, ratings, and trades.",
      category_id: category_ids["Games"],
      tags: ["board-games", "database", "reviews", "community"],
      originality: 75,
      human_authorship: 80,
      depth: 95,
      freshness: 88,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:indiegamemag" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@indiegamemag"),
      slug: "indiegamemag",
      name: "Indie Game Mag",
      url: "https://www.indiegamemag.com",
      domain: "indiegamemag.com",
      summary: "An independent magazine dedicated exclusively to indie games and their makers.",
      category_id: category_ids["Games"],
      tags: ["indie-games", "reviews", "news", "magazine"],
      originality: 70,
      human_authorship: 78,
      depth: 78,
      freshness: 80,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:home" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@home"),
      slug: "home",
      name: "Lostgarden",
      url: "https://lostgarden.home.blog",
      domain: "lostgarden.home.blog",
      summary: "Daniel Cook's long-running blog of game design essays, sprite art, and prototypes.",
      category_id: category_ids["Games"],
      tags: ["game-design", "essays", "art", "blog"],
      originality: 88,
      human_authorship: 90,
      depth: 85,
      freshness: 55,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:tigsource" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@tigsource"),
      slug: "tigsource",
      name: "TIGSource",
      url: "https://www.tigsource.com",
      domain: "tigsource.com",
      summary: "The granddaddy indie-games community blog, still running on old-school forum energy.",
      category_id: category_ids["Games"],
      tags: ["indie-games", "community", "blog", "devlogs"],
      originality: 85,
      human_authorship: 85,
      depth: 85,
      freshness: 55,
      design_quality: 60,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:smwhr" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@smwhr"),
      slug: "smwhr",
      name: "Crystal Cache",
      url: "https://www.smwhr.de",
      domain: "smwhr.de",
      summary: "A solo web-game dev's personal site of tiny js13k entries and candid devlogs.",
      category_id: category_ids["Games"],
      tags: ["js13k", "devlog", "web-games", "personal"],
      originality: 78,
      human_authorship: 88,
      depth: 70,
      freshness: 65,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:marginalia" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@marginalia"),
      slug: "marginalia",
      name: "Marginalia Search",
      url: "https://www.marginalia.nu/marginalia-search",
      domain: "marginalia.nu",
      summary: "A one-person search engine that deliberately surfaces small, non-commercial websites.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["search", "small-web", "non-commercial", "indie"],
      originality: 95,
      human_authorship: 92,
      depth: 85,
      freshness: 88,
      design_quality: 70,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:wiby" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@wiby"),
      slug: "wiby",
      name: "Wiby",
      url: "https://wiby.me",
      domain: "wiby.me",
      summary: "A search engine for the classic, lightweight web — pages that load even on a 486.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["search", "classic-web", "retro", "light"],
      originality: 92,
      human_authorship: 88,
      depth: 75,
      freshness: 75,
      design_quality: 55,
      featured: true,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:window-swap" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@window-swap"),
      slug: "window-swap",
      name: "Window Swap",
      url: "https://www.window-swap.com",
      domain: "window-swap.com",
      summary: "Look out of a stranger's window somewhere in the world. Then swap to another.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["window", "video", "travel", "calm"],
      originality: 92,
      human_authorship: 85,
      depth: 55,
      freshness: 65,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:pointerpointer" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@pointerpointer"),
      slug: "pointerpointer",
      name: "Pointer Pointer",
      url: "https://pointerpointer.com",
      domain: "pointerpointer.com",
      summary: "Move your mouse anywhere and a photo of a person pointing at your cursor appears. That's it.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["pointer", "cursor", "joke", "interactive"],
      originality: 90,
      human_authorship: 80,
      depth: 40,
      freshness: 50,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:cosmos" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@cosmos"),
      slug: "cosmos",
      name: "Cosmos",
      url: "https://cosmos.so",
      domain: "cosmos.so",
      summary: "A small community of artists and designers sharing visual inspiration without algorithms.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["moodboard", "inspiration", "community", "art"],
      originality: 82,
      human_authorship: 75,
      depth: 78,
      freshness: 85,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:merveilles" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@merveilles"),
      slug: "merveilles",
      name: "Merveilles",
      url: "https://merveilles.town",
      domain: "merveilles.town",
      summary: "A tightly themed, post-capitalist Mastodon instance for makers of curious small things.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["federation", "art", "community", "small-web"],
      originality: 88,
      human_authorship: 88,
      depth: 75,
      freshness: 85,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:melonland" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@melonland"),
      slug: "melonland",
      name: "Melonland",
      url: "https://melonland.net",
      domain: "melonland.net",
      summary: "A cozy forum and wiki for the small-web revival, with webrings, directories, and pixel art.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["small-web", "community", "forum", "webrings"],
      originality: 85,
      human_authorship: 88,
      depth: 80,
      freshness: 80,
      design_quality: 82,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:512kb" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@512kb"),
      slug: "512kb",
      name: "512kb Club",
      url: "https://512kb.club",
      domain: "512kb.club",
      summary: "A directory of websites whose entire homepage fits under 512KB. Bragging rights included.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["performance", "small-web", "directory", "green"],
      originality: 85,
      human_authorship: 85,
      depth: 70,
      freshness: 75,
      design_quality: 78,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:1mb" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@1mb"),
      slug: "1mb",
      name: "1MB Club",
      url: "https://1mb.club",
      domain: "1mb.club",
      summary: "A slightly more lenient sibling of the 512kb Club, for pages under 1 megabyte.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["performance", "small-web", "directory", "green"],
      originality: 78,
      human_authorship: 82,
      depth: 65,
      freshness: 65,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:xxiivv" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@xxiivv"),
      slug: "xxiivv",
      name: "XXIIVV",
      url: "https://wiki.xxiivv.com",
      domain: "wiki.xxiivv.com",
      summary: "Devine Lu Linvega's sprawling personal wiki of art, tools, sailing, and esoteric logs.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["wiki", "art", "esoteric", "personal"],
      originality: 95,
      human_authorship: 92,
      depth: 92,
      freshness: 80,
      design_quality: 88,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:xxiivv-2" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@xxiivv-2"),
      slug: "xxiivv-2",
      name: "Webring",
      url: "https://webring.xxiivv.com",
      domain: "webring.xxiivv.com",
      summary: "A hand-maintained webring of ~500 small, weird, personal sites — hit next and fall in.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["webring", "directory", "small-web", "indie"],
      originality: 88,
      human_authorship: 88,
      depth: 80,
      freshness: 85,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:cloak" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@cloak"),
      slug: "cloak",
      name: "Cloaku",
      url: "https://cloak.ist",
      domain: "cloak.ist",
      summary: "A pseudonymous maker's site of tiny web experiments and quiet observations.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["personal", "blog", "small-web", "experiments"],
      originality: 78,
      human_authorship: 85,
      depth: 68,
      freshness: 70,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:searx" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@searx"),
      slug: "searx",
      name: "Searx",
      url: "https://searx.be",
      domain: "searx.be",
      summary: "A privacy-respecting metasearch engine run by volunteers, no ads, no tracking.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["search", "privacy", "metasearch", "self-host"],
      originality: 78,
      human_authorship: 70,
      depth: 75,
      freshness: 80,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:robotie" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@robotie"),
      slug: "robotie",
      name: "Hyperdrive",
      url: "https://hyperdrive.robotie.dev",
      domain: "hyperdrive.robotie.dev",
      summary: "A hand-curated webring of design-y personal sites, with a delightful UI.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["webring", "small-web", "directory", "indie"],
      originality: 80,
      human_authorship: 82,
      depth: 70,
      freshness: 75,
      design_quality: 85,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:lurk" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@lurk"),
      slug: "lurk",
      name: "Lurk",
      url: "https://lurk.org",
      domain: "lurk.org",
      summary: "A small tilde-style community of artists, writers, and tinkerers on a shared *nix box.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["tilde", "community", "small-web", "shell"],
      originality: 78,
      human_authorship: 85,
      depth: 68,
      freshness: 65,
      design_quality: 62,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:yesterlinks" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@yesterlinks"),
      slug: "yesterlinks",
      name: "Yesterlinks",
      url: "https://yesterlinks.org",
      domain: "yesterlinks.org",
      summary: "A volunteer-run directory of hand-picked weird and wonderful sites across the indie web.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["directory", "small-web", "curation", "indie"],
      originality: 80,
      human_authorship: 85,
      depth: 75,
      freshness: 78,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:r4fo" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@r4fo"),
      slug: "r4fo",
      name: "Priviblur",
      url: "https://priviblur.r4fo.com",
      domain: "priviblur.r4fo.com",
      summary: "A privacy-fronted Tumblr viewer for when you want the weird posts without the tracking.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["tumblr", "privacy", "frontend", "proxy"],
      originality: 75,
      human_authorship: 70,
      depth: 65,
      freshness: 70,
      design_quality: 65,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:midnight" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@midnight"),
      slug: "midnight",
      name: "Midnight",
      url: "https://midnight.pub",
      domain: "midnight.pub",
      summary: "A virtual pub where strangers post short stories, poems, and notes at the witching hour.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["writing", "community", "fiction", "small-web"],
      originality: 88,
      human_authorship: 88,
      depth: 75,
      freshness: 70,
      design_quality: 80,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:blogspot-2" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@blogspot-2"),
      slug: "blogspot-2",
      name: "Mokalus",
      url: "https://mokalusoftheday.blogspot.com",
      domain: "mokalusoftheday.blogspot.com",
      summary: "A daily one-paragraph mokalus — a small, strange, often funny thought, posted since 2007.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["blog", "daily", "short", "ideas"],
      originality: 85,
      human_authorship: 90,
      depth: 55,
      freshness: 92,
      design_quality: 50,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:stumblerz" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@stumblerz"),
      slug: "stumblerz",
      name: "Stumblerz",
      url: "https://stumblerz.com",
      domain: "stumblerz.com",
      summary: "A StumbleUpon-style random page launcher that throws you into the weird indie web.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["stumbleupon", "random", "discovery", "indie"],
      originality: 82,
      human_authorship: 75,
      depth: 60,
      freshness: 75,
      design_quality: 75,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:defuse" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@defuse"),
      slug: "defuse",
      name: "Bogdan",
      url: "https://defuse.ca",
      domain: "defuse.ca",
      summary: "A security researcher's personal site of opinionated write-ups, demos, and curiosity.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["blog", "crypto", "hacker", "personal"],
      originality: 75,
      human_authorship: 85,
      depth: 75,
      freshness: 55,
      design_quality: 60,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed "directory-site:caramel" do
  GottaCc.Repo.insert!(
    %Site{
      id: UUID.uuid5(:oid, "GottaCc.Directory.Site@caramel"),
      slug: "caramel",
      name: "Caramel",
      url: "https://caramel.horse",
      domain: "caramel.horse",
      summary: "A small tilde/hackerspace for misfit makers, with shell accounts and a wiki of curiosities.",
      category_id: category_ids["Weird & Wonderful"],
      tags: ["hacker", "community", "tilde", "small-web"],
      originality: 80,
      human_authorship: 85,
      depth: 70,
      freshness: 70,
      design_quality: 72,
      featured: false,
      status: "published"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

