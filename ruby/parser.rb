class Parser
    def self.process_rr(splitted_line, contains_ttl, previous_ttl, previous_name, origin, ttl)

        rr = {}
        total_length = splitted_line.length
        isMx = Integer(splitted_line[total_length - 2], exception: false)

        case total_length
        when 5
            
        when 4
            for index in 0..total_length do
                element = splitted_line[index]
                if !element.nil?
                    if !element.include?('.')
                        if Integer(element, exception: false)
                            if !isMx
                                contains_ttl = true
                                previous_ttl = element
                                splitted_line.delete_at(index)
                            end
                        end
                    end
                end
            end
            if contains_ttl
                rr[:class] = splitted_line[0]
                rr[:type] = splitted_line[1]
                rr[:data] = splitted_line[2]
            else
                if isMx
                    previous_name = '@'
                    rr[:class] = splitted_line[0]
                    rr[:type] = splitted_line[1]
                    rr[:preference] = splitted_line[2]
                    rr[:data] = splitted_line[3]
                else
                    previous_name = splitted_line[0]
                    rr[:class] = splitted_line[1]
                    rr[:type] = splitted_line[2]
                    rr[:data] = splitted_line[3]
                end
            end
        when 3
            rr[:class] = splitted_line[0]
            rr[:type] = splitted_line[1]
            rr[:data] = splitted_line[2] 
        else
            
        end
        rr[:name] = previous_name || origin
        rr[:ttl] = previous_ttl || ttl

        return rr, previous_name, previous_ttl
        
    end
    def self.compute(file_path)
        records = {}
        supported_record_types = ['SOA', 'NS', 'A', 'CNAME', 'MX']
        supported_record_types.each  {|record_type| records[record_type] = []}

        soa = {
            ttl: 0,
            mname: '',
            rname: '',
            serial: 0,
            refresh: 0,
            retry: 0,
            expire: 0,
            minimum: 0
        }
        soa_line_count = 0
        multi_line_soa = false

        contains_ttl = false
        type = 'SOA'

        origin = ''
        ttl = 0

        previous_name = ''
        previous_ttl = 0

        File.open(file_path).each do |line|
            commented_line = false
            l = line.chomp
                    .gsub(/\t/, ' ')
                    .gsub(/\s+/, ' ')
            if l.length > 1
                

                comment_index = l.index(';')

                if !comment_index.nil?
                    if comment_index != 0
                        m = l.split(';')
                        l = m[0]
                    else
                        commented_line = true
                    end
                
                end

                if !commented_line
                    
                    splitted_line = l.split(' ')
                    
                    case splitted_line[0]
                    when '$ORIGIN'
                        origin = splitted_line[1]
                        
                    when '$TTL' 
                        ttl = splitted_line[1]
                    when '$INCLUDE'
                        # TODO
                    else
                        if splitted_line.include?('SOA')
                            previous_name = splitted_line[0]
                            soa[:name] = previous_name
                            soa[:mname] = splitted_line[3]
                            soa[:rname] = splitted_line[4]
                            if splitted_line.include?(')')
                                
                                soa[:serial] = splitted_line[6]
                                soa[:refresh] = splitted_line[7]
                                soa[:retry] = splitted_line[8]
                                soa[:expire] = splitted_line[9]
                                soa[:minimum] = splitted_line[10]
                                
                                records['SOA'].push(soa)
                            else
                                multi_line_soa = true
                                soa_line_count = soa_line_count + 1
                                
                            end
                        
                        end

                        supported_record_types.each do |element|
                            if splitted_line.include?(element)
                                type = element
                                if type != 'SOA'
                                    rr, previous_name, previous_ttl = process_rr(splitted_line, contains_ttl, previous_ttl, previous_name,
                                    origin, ttl)
                                    records[type].push(rr)
                                end
                            end
                        end
                    end

                    if multi_line_soa
                        case soa_line_count
                        when 2
                            soa[:serial] = splitted_line[0]
                            
                        when 3
                            soa[:refresh] = splitted_line[0] 
                        when 4
                            soa[:retry] = splitted_line[0] 

                        when 5
                            soa[:expire] = splitted_line[0] 
                        when 6
                            soa[:minimum] = splitted_line[0]     
                        else
                            
                        end
                        if splitted_line.include?(')')
                            multi_line_soa = false
                            records['SOA'].push(soa)
                        end
                    end
                end
            end
            
        end
        return records
    end    # return records

end