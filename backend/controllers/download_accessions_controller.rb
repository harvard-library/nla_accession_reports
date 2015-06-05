require 'csv'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/download_accessions')
    .description("Download Accessions as CSV")
    .params(*BASE_SEARCH_PARAMS,
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, ""]) \
  do

    [200, some_headers, content]

  end


  def some_headers
    {
      "Content-Type" => "text/csv; charset=UTF-8",
      "Content-Disposition" => "attachment; filename=\"accessions_#{Time.now.iso8601}.csv\""
    }
  end


  def content
    params[:filter_term] ||= []
    params[:filter_term] << {'primary_type' => 'accession'}.to_json
    params[:page] = 1
    params[:page_size] = 100

    CSV.generate do |csv|
      csv << column_headings

      while true
        resp = Search.search(params, params[:repo_id])

        resp['results'].each do |r|
          j = ASUtils.json_parse(r['json'])
          ud = j['user_defined'] || {}
          extent = j['extents'].first || {}
          csv << [
                  r['title'],
                  r['identifier'],
                  r['accession_date'],
                  j['content_description'],
                  j['inventory'],
                  j['retention_rule'],
                  j['access_restrictions_note'],
                  format_dates(j['dates']),
                  extent['number'],
                  extent['extent_type'],
                  extent['container_summary'],
                  format_subjects(r['subjects']),
                  ud['text_2'],
                  ud['text_3'],
                  ud['text_4'],
                  ud['enum_2'],
                 ]
        end

        if params[:page] < resp['last_page']
          params[:page] += 1
        else
          break
        end
      end
    end
  end


  def column_headings
    [
     'Title', 'Identifier', 'Accession Date', 'Content Description',
     'Inventory', 'Retention Rule', 'Access Restrictions Note',
     'Dates', 'Extent Number', 'Extent Type', 'Extent Container Summary',
     'Subjects', 'Preservation Notes', 'Volunteers Projects',
     'Special Format Notes', 'Preservation Status'
    ]
  end


  def format_dates(dates)
    return if dates.empty?
    dates.map do |d|
      be = [d['begin'], d['end']].compact.join(' to ')
      bee = [be, d['expression']].compact.join(' - ')
      "#{d['label']}: #{bee}"
    end.join("; ")
  end


  def format_subjects(subjects)
    return unless subjects
    subjects.join('; ')
  end

end

