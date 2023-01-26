#!/usr/bin/ruby
require_relative '../../../../lib/objects/local_string_encoder.rb'
require 'sqlite3'

class FirefoxPlacesGenerator < StringEncoder
  attr_accessor :search_category
  attr_accessor :url_count
  attr_accessor :db
  # TODO: Assign variable on where places.sqlite will go

  def initialize
    super
    self.module_name = 'Firefox Places Generator'
    self.search_category = ''
    self.url_count = ''
    File.delete("places.sqlite") if File.exist?("places.sqlite")
    self.db = SQLite3::Database.new "places.sqlite"
  end

  def process_options(opt, arg)
    super
    if opt == '--SEARCH_CATEGORY'
      self.search_category << arg
    end
    if opt == '--URL_COUNT'
      self.url_count << arg
    end
  end
  
  def get_options_array
    super + [['--SEARCH_CATEGORY', '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--URL_COUNT', '-u', GetoptLong::OPTIONAL_ARGUMENT]
  ]
  end

  def create_places(db)
    #TODO - Read from sql file to remove clutter
    sql = <<SQL
      CREATE TABLE IF NOT EXISTS "moz_origins" (
        "id"	INTEGER,
        "prefix"	TEXT NOT NULL,
        "host"	TEXT NOT NULL,
        "frecency"	INTEGER NOT NULL,
        PRIMARY KEY("id"),
        UNIQUE("prefix","host")
      );
      CREATE TABLE IF NOT EXISTS "moz_places" (
        "id"	INTEGER,
        "url"	LONGVARCHAR,
        "title"	LONGVARCHAR,
        "rev_host"	LONGVARCHAR,
        "visit_count"	INTEGER DEFAULT 0,
        "hidden"	INTEGER NOT NULL DEFAULT 0,
        "typed"	INTEGER NOT NULL DEFAULT 0,
        "frecency"	INTEGER NOT NULL DEFAULT -1,
        "last_visit_date"	INTEGER,
        "guid"	TEXT,
        "foreign_count"	INTEGER NOT NULL DEFAULT 0,
        "url_hash"	INTEGER NOT NULL DEFAULT 0,
        "description"	TEXT,
        "preview_image_url"	TEXT,
        "origin_id"	INTEGER,
        "site_name"	TEXT,
        PRIMARY KEY("id"),
        FOREIGN KEY("origin_id") REFERENCES "moz_origins"("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_historyvisits" (
        "id"	INTEGER,
        "from_visit"	INTEGER,
        "place_id"	INTEGER,
        "visit_date"	INTEGER,
        "visit_type"	INTEGER,
        "session"	INTEGER,
        "source"	INTEGER NOT NULL DEFAULT 0,
        "triggeringPlaceId"	INTEGER,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_inputhistory" (
        "place_id"	INTEGER NOT NULL,
        "input"	LONGVARCHAR NOT NULL,
        "use_count"	INTEGER,
        PRIMARY KEY("place_id","input")
      );
      CREATE TABLE IF NOT EXISTS "moz_bookmarks" (
        "id"	INTEGER,
        "type"	INTEGER,
        "fk"	INTEGER DEFAULT NULL,
        "parent"	INTEGER,
        "position"	INTEGER,
        "title"	LONGVARCHAR,
        "keyword_id"	INTEGER,
        "folder_type"	TEXT,
        "dateAdded"	INTEGER,
        "lastModified"	INTEGER,
        "guid"	TEXT,
        "syncStatus"	INTEGER NOT NULL DEFAULT 0,
        "syncChangeCounter"	INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_bookmarks_deleted" (
        "guid"	TEXT,
        "dateRemoved"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("guid")
      );
      CREATE TABLE IF NOT EXISTS "moz_keywords" (
        "id"	INTEGER,
        "keyword"	TEXT UNIQUE,
        "place_id"	INTEGER,
        "post_data"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
      CREATE TABLE IF NOT EXISTS "moz_anno_attributes" (
        "id"	INTEGER,
        "name"	VARCHAR(32) NOT NULL UNIQUE,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_annos" (
        "id"	INTEGER,
        "place_id"	INTEGER NOT NULL,
        "anno_attribute_id"	INTEGER,
        "content"	LONGVARCHAR,
        "flags"	INTEGER DEFAULT 0,
        "expiration"	INTEGER DEFAULT 0,
        "type"	INTEGER DEFAULT 0,
        "dateAdded"	INTEGER DEFAULT 0,
        "lastModified"	INTEGER DEFAULT 0,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_items_annos" (
        "id"	INTEGER,
        "item_id"	INTEGER NOT NULL,
        "anno_attribute_id"	INTEGER,
        "content"	LONGVARCHAR,
        "flags"	INTEGER DEFAULT 0,
        "expiration"	INTEGER DEFAULT 0,
        "type"	INTEGER DEFAULT 0,
        "dateAdded"	INTEGER DEFAULT 0,
        "lastModified"	INTEGER DEFAULT 0,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_meta" (
        "key"	TEXT,
        "value"	 NOT NULL,
        PRIMARY KEY("key")
      ) WITHOUT ROWID;
      CREATE TABLE IF NOT EXISTS "moz_places_metadata" (
        "id"	INTEGER,
        "place_id"	INTEGER NOT NULL,
        "referrer_place_id"	INTEGER,
        "created_at"	INTEGER NOT NULL DEFAULT 0,
        "updated_at"	INTEGER NOT NULL DEFAULT 0,
        "total_view_time"	INTEGER NOT NULL DEFAULT 0,
        "typing_time"	INTEGER NOT NULL DEFAULT 0,
        "key_presses"	INTEGER NOT NULL DEFAULT 0,
        "scrolling_time"	INTEGER NOT NULL DEFAULT 0,
        "scrolling_distance"	INTEGER NOT NULL DEFAULT 0,
        "document_type"	INTEGER NOT NULL DEFAULT 0,
        "search_query_id"	INTEGER,
        PRIMARY KEY("id"),
        FOREIGN KEY("place_id") REFERENCES "moz_places"("id") ON DELETE CASCADE,
        FOREIGN KEY("referrer_place_id") REFERENCES "moz_places"("id") ON DELETE CASCADE,
        FOREIGN KEY("search_query_id") REFERENCES "moz_places_metadata_search_queries"("id") ON DELETE CASCADE,
        CHECK("place_id" != "referrer_place_id")
      );
      CREATE TABLE IF NOT EXISTS "moz_places_metadata_search_queries" (
        "id"	INTEGER,
        "terms"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_places_metadata_snapshots" (
        "place_id"	INTEGER,
        "created_at"	INTEGER NOT NULL,
        "removed_at"	INTEGER,
        "first_interaction_at"	INTEGER NOT NULL,
        "last_interaction_at"	INTEGER NOT NULL,
        "document_type"	INTEGER NOT NULL DEFAULT 0,
        "user_persisted"	INTEGER NOT NULL DEFAULT 0,
        "title"	TEXT,
        "removed_reason"	INTEGER,
        PRIMARY KEY("place_id"),
        FOREIGN KEY("place_id") REFERENCES "moz_places"("id") ON DELETE CASCADE
      );
      CREATE TABLE IF NOT EXISTS "moz_places_metadata_snapshots_extra" (
        "place_id"	INTEGER NOT NULL,
        "type"	INTEGER NOT NULL DEFAULT 0,
        "data"	TEXT NOT NULL,
        PRIMARY KEY("place_id","type"),
        FOREIGN KEY("place_id") REFERENCES "moz_places_metadata_snapshots"("place_id") ON DELETE CASCADE
      ) WITHOUT ROWID;
      CREATE TABLE IF NOT EXISTS "moz_places_metadata_snapshots_groups" (
        "id"	INTEGER,
        "builder"	TEXT NOT NULL,
        "builder_data"	TEXT,
        "hidden"	INTEGER NOT NULL DEFAULT 0,
        "title"	TEXT,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_places_metadata_groups_to_snapshots" (
        "group_id"	INTEGER NOT NULL,
        "place_id"	INTEGER NOT NULL,
        "hidden"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("group_id","place_id"),
        FOREIGN KEY("group_id") REFERENCES "moz_places_metadata_snapshots_groups"("id") ON DELETE CASCADE,
        FOREIGN KEY("place_id") REFERENCES "moz_places_metadata_snapshots"("place_id") ON DELETE CASCADE
      ) WITHOUT ROWID;
      CREATE TABLE IF NOT EXISTS "moz_session_metadata" (
        "id"	INTEGER,
        "guid"	TEXT NOT NULL UNIQUE,
        "last_saved_at"	INTEGER NOT NULL DEFAULT 0,
        "data"	TEXT,
        PRIMARY KEY("id")
      );
      CREATE TABLE IF NOT EXISTS "moz_session_to_places" (
        "session_id"	INTEGER NOT NULL,
        "place_id"	INTEGER NOT NULL,
        "position"	INTEGER,
        PRIMARY KEY("session_id","place_id"),
        FOREIGN KEY("session_id") REFERENCES "moz_session_metadata"("id") ON DELETE CASCADE,
        FOREIGN KEY("place_id") REFERENCES "moz_places"("id") ON DELETE CASCADE
      ) WITHOUT ROWID;
      CREATE TABLE IF NOT EXISTS "moz_previews_tombstones" (
        "hash"	TEXT,
        PRIMARY KEY("hash")
      ) WITHOUT ROWID;
      CREATE INDEX IF NOT EXISTS "moz_places_url_hashindex" ON "moz_places" (
        "url_hash"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_hostindex" ON "moz_places" (
        "rev_host"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_visitcount" ON "moz_places" (
        "visit_count"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_frecencyindex" ON "moz_places" (
        "frecency"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_lastvisitdateindex" ON "moz_places" (
        "last_visit_date"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_places_guid_uniqueindex" ON "moz_places" (
        "guid"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_originidindex" ON "moz_places" (
        "origin_id"
      );
      CREATE INDEX IF NOT EXISTS "moz_historyvisits_placedateindex" ON "moz_historyvisits" (
        "place_id",
        "visit_date"
      );
      CREATE INDEX IF NOT EXISTS "moz_historyvisits_fromindex" ON "moz_historyvisits" (
        "from_visit"
      );
      CREATE INDEX IF NOT EXISTS "moz_historyvisits_dateindex" ON "moz_historyvisits" (
        "visit_date"
      );
      CREATE INDEX IF NOT EXISTS "moz_bookmarks_itemindex" ON "moz_bookmarks" (
        "fk",
        "type"
      );
      CREATE INDEX IF NOT EXISTS "moz_bookmarks_parentindex" ON "moz_bookmarks" (
        "parent",
        "position"
      );
      CREATE INDEX IF NOT EXISTS "moz_bookmarks_itemlastmodifiedindex" ON "moz_bookmarks" (
        "fk",
        "lastModified"
      );
      CREATE INDEX IF NOT EXISTS "moz_bookmarks_dateaddedindex" ON "moz_bookmarks" (
        "dateAdded"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_bookmarks_guid_uniqueindex" ON "moz_bookmarks" (
        "guid"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_keywords_placepostdata_uniqueindex" ON "moz_keywords" (
        "place_id",
        "post_data"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_annos_placeattributeindex" ON "moz_annos" (
        "place_id",
        "anno_attribute_id"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_items_annos_itemattributeindex" ON "moz_items_annos" (
        "item_id",
        "anno_attribute_id"
      );
      CREATE UNIQUE INDEX IF NOT EXISTS "moz_places_metadata_placecreated_uniqueindex" ON "moz_places_metadata" (
        "place_id",
        "created_at"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_metadata_referrerindex" ON "moz_places_metadata" (
        "referrer_place_id"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_metadata_snapshots_pinnedindex" ON "moz_places_metadata_snapshots" (
        "user_persisted",
        "last_interaction_at"
      );
      CREATE INDEX IF NOT EXISTS "moz_places_metadata_snapshots_extra_typeindex" ON "moz_places_metadata_snapshots_extra" (
        "type"
      );
      
SQL
    db.execute_batch (sql)                      #ID|         URL        |title|   rev_host    | visit |hidden|typed|frecency|last_visit_date | guid | foreign | url_+hash | Description | preview_image | origin_id | site_name
    db.execute("INSERT INTO 'moz_places' VALUES (1,   'www.google.com',   '', 'moc.elgoog.www.', '1',   '0',   '1',   100,  '1672174919664000', '0',    '',        '',     'Description',       '',    '1', '');")
    db.execute("INSERT INTO 'moz_origins' VALUES ('1', 'https://', 'www.google.com', '2100');")
    db.execute("INSERT INTO 'moz_meta' VALUES ('origin_frecency_count', '3');")
    db.execute("INSERT INTO 'moz_meta' VALUES ('origin_frecency_sum', '4125');")
    db.execute("INSERT INTO 'moz_meta' VALUES ('origin_frecency_sum_of_squares', '8410625');")
    db.execute("INSERT INTO 'moz_meta' VALUES ('sync/bookmarks/wiperemote', '0');")
    db.execute("ANALYZE moz_places;")
    db.execute("ANALYZE moz_historyvisits;")
    db.execute("ANALYZE moz_bookmarks;")
  end
    
  def encode_all
    create_places(self.db)
    iterations = 1
    currentiter = 1
    while currentiter <= iterations
      #self.db.execute("INSERT INTO 'moz_places' VALUES (#{currentiter},'https://','www.google.com',300);")
      currentiter += 1
    end
    db.execute("select * from moz_places") do |row|
      self.outputs << row
    end
  end

  # def encode_all
  #   iterations = self.iterations.to_i
  #   currentiter = 1
  #   while currentiter <= iterations
  #     google_base = "https://www.google.com/search?q="
  #     search = craft_search
  #     self.outputs << "#{google_base}#{search}"
  #     currentiter += 1
  #   end
  # end

  def encoding_print_string
    'Search Category: ' + self.search_category.to_s + ' | URL Count: ' + self.url_count
  end
  
  # def generate
  #   # read all the lines, and select one at random
  #   line = File.readlines("#{LINELISTS_DIR}/#{self.linelist.sample.chomp}").sample.chomp
  #   # strip out everything except alphanumeric and basic punctuation (no ' or ")
  #   self.outputs << line.gsub(/[^\w !.,]/, '')
  # end
end

FirefoxPlacesGenerator.new.run