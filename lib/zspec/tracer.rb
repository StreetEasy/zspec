module ZSpec
  class Tracer
    def initialize
      begin
        create_specs_table
      rescue
      end
    end

    def start_build
      begin
        connection.exec("INSERT INTO specs (build_number, node_name, pod_name, spec, spec_started)
          VALUES (#{ENV['ZSPEC_BUILD_NUMBER']}, '#{ENV['NODE_NAME']}', '#{ENV['POD_NAME']}', '#{ENV['ZSPEC_BUILD_NUMBER']}', #{Time.now.to_i});")
      rescue
      end
    end

    def stop_build
      begin
        connection.exec("UPDATE specs SET spec_stopped = #{Time.now.to_i} WHERE spec = '#{ENV['ZSPEC_BUILD_NUMBER']}';")
      rescue
      end
    end

    def start_worker
      begin
        connection.exec("INSERT INTO specs (build_number, node_name, pod_name, spec, spec_started)
          VALUES (#{ENV['ZSPEC_BUILD_NUMBER']}, '#{ENV['NODE_NAME']}', '#{ENV['POD_NAME']}', '#{ENV['POD_NAME']}', #{Time.now.to_i}) RETURNING id;").getvalue(0,0)
      rescue
      end
    end

    def stop_worker(spec_id)
      begin
        connection.exec("UPDATE specs SET spec_stopped = #{Time.now.to_i} WHERE id = #{spec_id};")
      rescue
      end
    end

    def start_spec(message)
      begin
        connection.exec("INSERT INTO specs (build_number, node_name, pod_name, spec, spec_started)
          VALUES (#{ENV['ZSPEC_BUILD_NUMBER']}, '#{ENV['NODE_NAME']}', '#{ENV['POD_NAME']}', '#{message}', #{Time.now.to_i}) RETURNING id;").getvalue(0,0)
      rescue
      end
    end

    def end_spec(spec_id)
      begin
        connection.exec("UPDATE specs SET spec_stopped = #{Time.now.to_i} WHERE id = #{spec_id};")
      rescue
      end
    end

    private

    def connection
      PG::Connection.new(
        host: ENV["ZSPEC_POSTGRES_HOST"],
        user: ENV["ZSPEC_POSTGRES_USER"],
        dbname: ENV["ZSPEC_POSTGRES_DB"],
        password: ENV["ZSPEC_POSTGRES_PASSWORD"],
        port: '5432')
    end

    def create_specs_table
      connection.exec("
        CREATE TABLE IF NOT EXISTS specs (
        id             SERIAL PRIMARY KEY
        ,build_number  INTEGER
        ,node_name     VARCHAR(250)
        ,pod_name      VARCHAR(250)
        ,spec          VARCHAR(250)
        ,spec_started  INTEGER
        ,spec_stopped  INTEGER
        );")
    end
  end
end
