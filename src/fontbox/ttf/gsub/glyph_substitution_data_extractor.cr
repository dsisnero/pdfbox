require "../ttf_tables"

module Fontbox::TTF::Gsub
  Model = ::Fontbox::TTF::Model

  class GlyphSubstitutionDataExtractor
    Log = ::Log.for(self)

    def gsub_data(script_list : Hash(String, ScriptTable),
                  feature_list_table : FeatureListTable,
                  lookup_list_table : LookupListTable) : ::Fontbox::TTF::Model::GsubData
      script_table_details = supported_language(script_list)

      if script_table_details.nil?
        return ::Fontbox::TTF::Model::GsubData::NO_DATA_FOUND
      end
      build_map_backed_gsub_data(feature_list_table, lookup_list_table, script_table_details)
    end

    def gsub_data(script_name : String, script_table : ScriptTable,
                  feature_list_table : FeatureListTable,
                  lookup_list_table : LookupListTable) : ::Fontbox::TTF::Model::GsubData
      script_table_details = ScriptTableDetails.new(::Fontbox::TTF::Model::Language::UNSPECIFIED,
        script_name, script_table)

      build_map_backed_gsub_data(feature_list_table, lookup_list_table, script_table_details)
    end

    private def build_map_backed_gsub_data(feature_list_table : FeatureListTable,
                                           lookup_list_table : LookupListTable,
                                           script_table_details : ScriptTableDetails) : ::Fontbox::TTF::Model::MapBackedGsubData
      script_table = script_table_details.script_table

      gsub_data = Hash(String, Hash(Array(Int32), Array(Int32))).new
      default_lang_sys = script_table.default_lang_sys_table
      if default_lang_sys
        populate_gsub_data(gsub_data, default_lang_sys, feature_list_table,
          lookup_list_table)
      end
      script_table.lang_sys_tables.each_value do |lang_sys_table|
        populate_gsub_data(gsub_data, lang_sys_table, feature_list_table, lookup_list_table)
      end

      ::Fontbox::TTF::Model::MapBackedGsubData.new(script_table_details.language,
        script_table_details.feature_name, gsub_data)
    end

    private def supported_language(script_list : Hash(String, ScriptTable)) : ScriptTableDetails?
      ::Fontbox::TTF::Model::Language.each do |lang|
        lang.script_names.each do |script_name|
          value = script_list[script_name]?
          if value
            Log.debug { "Language decided: #{lang} #{script_name}" }
            return ScriptTableDetails.new(lang, script_name, value)
          end
        end
      end
      nil
    end

    private def populate_gsub_data(gsub_data : Hash(String, Hash(Array(Int32), Array(Int32))),
                                   lang_sys_table : LangSysTable,
                                   feature_list_table : FeatureListTable,
                                   lookup_list_table : LookupListTable)
      feature_records = feature_list_table.feature_records
      lang_sys_table.feature_indices.each do |feature_index|
        if feature_index < feature_records.size
          populate_gsub_data(gsub_data, feature_records[feature_index], lookup_list_table)
        end
      end
    end

    # Creates a Map<List<Integer>, Integer> from the lookup tables
    private def populate_gsub_data(gsub_data : Hash(String, Hash(Array(Int32), Array(Int32))),
                                   feature_record : FeatureRecord,
                                   lookup_list_table : LookupListTable)
      lookups = lookup_list_table.lookups
      glyph_substitution_map = Hash(Array(Int32), Array(Int32)).new
      feature_record.feature_table.lookup_list_indices.each do |lookup_index|
        if lookup_index < lookups.size
          extract_data(glyph_substitution_map, lookups[lookup_index])
        end
      end

      Log.debug { "*********** extracting GSUB data for the feature: #{feature_record.feature_tag}, glyph_substitution_map: #{glyph_substitution_map}" }

      gsub_data[feature_record.feature_tag] = glyph_substitution_map
    end

    private def extract_data(glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
                             lookup_table : LookupTable)
      lookup_table.sub_tables.each do |lookup_sub_table|
        case lookup_sub_table
        when LookupTypeLigatureSubstitutionSubstFormat1
          extract_data_from_ligature_substitution_subst_format1_table(glyph_substitution_map,
            lookup_sub_table.as(LookupTypeLigatureSubstitutionSubstFormat1))
        when LookupTypeAlternateSubstitutionFormat1
          extract_data_from_alternate_substitution_subst_format1_table(glyph_substitution_map,
            lookup_sub_table.as(LookupTypeAlternateSubstitutionFormat1))
        when LookupTypeSingleSubstFormat1
          extract_data_from_single_subst_table_format1_table(glyph_substitution_map,
            lookup_sub_table.as(LookupTypeSingleSubstFormat1))
        when LookupTypeSingleSubstFormat2
          extract_data_from_single_subst_table_format2_table(glyph_substitution_map,
            lookup_sub_table.as(LookupTypeSingleSubstFormat2))
        when LookupTypeMultipleSubstitutionFormat1
          extract_data_from_multiple_substitution_format1_table(glyph_substitution_map,
            lookup_sub_table.as(LookupTypeMultipleSubstitutionFormat1))
        else
          # usually null, due to being skipped in GlyphSubstitutionTable.readLookupTable()
          Log.debug { "The type #{lookup_sub_table} is not yet supported, will be ignored" }
        end
      end
    end

    private def extract_data_from_single_subst_table_format1_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      single_subst_table_format1 : LookupTypeSingleSubstFormat1,
    )
      coverage_table = single_subst_table_format1.coverage_table
      (0...coverage_table.size).each do |i|
        coverage_glyph_id = coverage_table.glyph_id(i)
        substitute_glyph_id = coverage_glyph_id + single_subst_table_format1.delta_glyph_id
        put_new_substitution_entry(glyph_substitution_map, [substitute_glyph_id],
          [coverage_glyph_id])
      end
    end

    private def extract_data_from_single_subst_table_format2_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      single_subst_table_format2 : LookupTypeSingleSubstFormat2,
    )
      coverage_table = single_subst_table_format2.coverage_table

      if coverage_table.size != single_subst_table_format2.substitute_glyph_ids.size
        Log.warn { "The coverage table size (#{coverage_table.size}) should be the same as the count of the substituteGlyphIDs tables (#{single_subst_table_format2.substitute_glyph_ids.size})" }
        return
      end

      (0...coverage_table.size).each do |i|
        coverage_glyph_id = coverage_table.glyph_id(i)
        substitute_glyph_id = single_subst_table_format2.substitute_glyph_ids[i]
        put_new_substitution_entry(glyph_substitution_map, [substitute_glyph_id],
          [coverage_glyph_id])
      end
    end

    private def extract_data_from_multiple_substitution_format1_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      multiple_subst_format1_subtable : LookupTypeMultipleSubstitutionFormat1,
    )
      coverage_table = multiple_subst_format1_subtable.coverage_table

      if coverage_table.size != multiple_subst_format1_subtable.sequence_tables.size
        Log.warn { "The coverage table size (#{coverage_table.size}) should be the same as the count of the sequence tables (#{multiple_subst_format1_subtable.sequence_tables.size})" }
        return
      end

      (0...coverage_table.size).each do |i|
        coverage_glyph_id = coverage_table.glyph_id(i)
        sequence_table = multiple_subst_format1_subtable.sequence_tables[i]
        substitute_glyph_id_array = sequence_table.substitute_glyph_ids
        substitute_glyph_id_list = substitute_glyph_id_array.to_a
        put_new_substitution_entry(glyph_substitution_map,
          substitute_glyph_id_list,
          [coverage_glyph_id])
      end
    end

    private def extract_data_from_ligature_substitution_subst_format1_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      ligature_substitution_table : LookupTypeLigatureSubstitutionSubstFormat1,
    )
      ligature_substitution_table.ligature_set_tables.each do |ligature_set_table|
        ligature_set_table.ligature_tables.each do |ligature_table|
          extract_data_from_ligature_table(glyph_substitution_map, ligature_table)
        end
      end
    end

    private def extract_data_from_alternate_substitution_subst_format1_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      alternate_substitution_format1 : LookupTypeAlternateSubstitutionFormat1,
    )
      coverage_table = alternate_substitution_format1.coverage_table

      if coverage_table.size != alternate_substitution_format1.alternate_set_tables.size
        Log.warn { "The coverage table size (#{coverage_table.size}) should be the same as the count of the alternate set tables (#{alternate_substitution_format1.alternate_set_tables.size})" }
        return
      end

      (0...coverage_table.size).each do |i|
        coverage_glyph_id = coverage_table.glyph_id(i)
        sequence_table = alternate_substitution_format1.alternate_set_tables[i]

        # Loop through the substitute glyphs and pick the first one that is not the same as the coverage glyph
        sequence_table.alternate_glyph_ids.each do |alternate_glyph_id|
          if alternate_glyph_id != coverage_glyph_id
            put_new_substitution_entry(glyph_substitution_map, [alternate_glyph_id],
              [coverage_glyph_id])
            break
          end
        end
      end
    end

    private def extract_data_from_ligature_table(
      glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
      ligature_table : LigatureTable,
    )
      component_glyph_ids = ligature_table.component_glyph_ids
      glyphs_to_be_substituted = component_glyph_ids.to_a

      Log.debug { "glyphsToBeSubstituted: #{glyphs_to_be_substituted}" }

      put_new_substitution_entry(glyph_substitution_map, [ligature_table.ligature_glyph],
        glyphs_to_be_substituted)
    end

    private def put_new_substitution_entry(glyph_substitution_map : Hash(Array(Int32), Array(Int32)),
                                           new_glyph_list : Array(Int32),
                                           glyphs_to_be_substituted : Array(Int32))
      old_values = glyph_substitution_map[glyphs_to_be_substituted]?
      glyph_substitution_map[glyphs_to_be_substituted] = new_glyph_list

      if old_values
        Log.debug { "For the newGlyph: #{new_glyph_list}, newValue: #{glyphs_to_be_substituted} is trying to override the oldValue #{old_values}" }
      end
    end

    private class ScriptTableDetails
      getter language : ::Fontbox::TTF::Model::Language
      getter feature_name : String
      getter script_table : ScriptTable

      def initialize(@language : ::Fontbox::TTF::Model::Language, @feature_name : String, @script_table : ScriptTable)
      end
    end
  end
end
