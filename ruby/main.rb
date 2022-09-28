require 'socket'
require './parser'
# require 'io'

host = "127.0.0.1"
port = 53

socket = UDPSocket.new

socket.bind(host, port)

def binary_string_to_hex(data)
    return data.to_i(2).to_s(16).rjust(4,'0').scan(/../).map {|x| x.hex.chr}.join
end

def get_flags(data)
    qr = '1'

    op_code = '0000'

    aa = '1'

    tc = '0'

    rd = '0'

    ra = '0'

    z = '000'

    rcode = '0000'

    header1 = qr + op_code + aa + tc + rd
    header2 = ra + z + rcode

    return binary_string_to_hex(header1 + header2)
end

def hex_to_decimal(data)
    return data.gsub("\\x", '').to_i()
end

def get_domain(data)
    buf = IO::Buffer.for(data)
   
    # p data
    state = 0
    expected_length = 0
    domain = '';
    domain_parts = []
    x = 0
    y = 0
    index = 0
    
    loop do
        if state == 1
            if expected_length == 0
                break
            end
            for index in x+1..x+expected_length do
                domain += buf.get_value(:U8, index).chr
                # p domain
            end
            domain_parts.push(domain)
            domain = ''
            x = index + 1
            state = 0
            
        else
            state = 1
            expected_length = buf.get_value(:U8, x)
        end

    end

    #ToDo: Get 2 more bytes for record type
    record_type =  buf.get_value(:U8, x+2)
    
    return [domain_parts, record_type]
    
end

def get_record_type_str(record_type_decimal)
    record_type_str = ''
    
    case record_type_decimal
    when 1
        record_type_str = 'A'
    when 2
        record_type_str = 'NS'
    when 5
        record_type_str = 'CNAME'
    when 6
        record_type_str = 'SOA'
    when 12
        record_type_str = 'PTR'
    when 15
        record_type_str = 'MX'
    else
        
    end
    return record_type_str
end

def get_records(data)
    recrods_result = []
    asked_record = ''
    domain, record_type_decimal = get_domain(data)

    asked_record = '@'
    if domain.length > 2
        asked_record = domain[0]
        domain_name = domain[1] + '.' + domain[2]
    else
        domain_name = domain.join('.')
    end

    record_type_str = get_record_type_str(record_type_decimal)

    file_path = "zones/#{domain_name}.zone"

    records = Parser.compute(file_path)

    # pp records

    return records, record_type_str, domain, asked_record
end

def get_record_type_hex(record_type_str)
    record_type_hex = ''
    case record_type_str
    when 'A' 
        record_type_hex = '0001'
    when 'NS' 
        record_type_hex = '0002'
    when 'CNAME' 
        record_type_hex = '0005'
    when 'SOA' 
        record_type_hex = '0006'
    when 'PTR' 
        record_type_hex = '000c' 
    when 'MX' 
        record_type_hex = '000f'  
    when 'TXT' 
        record_type_hex = '0010'  
    else
        
    end
    return record_type_hex
end

def domain_to_hex(to_split_domain)
    domain = ''
    domain_length = 0
    bytes = ''
    for word in to_split_domain.split('.') do
        bytes = ''
        for char in word.split('') do
            bytes += char.ord.to_s(16).rjust(2, '0')
        end
        domain_length = (bytes.length / 2).to_s(16).rjust(2,'0')
        domain += domain_length + bytes
    end

    return domain + '00'
end

def string_to_hex(str)
    Integer(str).to_s(16).rjust(8,'0')
end

def record_to_bytes(record_type, record)
    bytes = 'c00c'

    bytes += get_record_type_hex(record_type)

    bytes += '0001'

    bytes += Integer(record[:ttl]).to_s(16).rjust(8, '0')

    alphabet_domain = ''

    if record_type == 'A'
        bytes += '0004'
        for part in record[:data].split('.') do
            bytes += Integer(part).to_s(16).rjust(2, '0')
        end
    elsif record_type == 'SOA'
        mname = domain_to_hex(record[:mname]) 
        rname = domain_to_hex(record[:rname]) 
        serial = string_to_hex(record[:serial])
        refresh = string_to_hex(record[:refresh])
        retry_ = string_to_hex(record[:retry])
        expire = string_to_hex(record[:expire])
        minimum = string_to_hex(record[:minimum])

        alphabet_domain += mname + rname + serial + refresh + retry_ + expire + minimum
    else
        alphabet_domain = domain_to_hex(record[:data])
    end

    if alphabet_domain != ''
        case record_type
        when 'MX'
            alphabet_domain = Integer(record[:preference]).to_s(16).rjust(4,'0') + alphabet_domain
            
        else
            
        end
        total_length = (alphabet_domain.length / 2).to_s(16).rjust(4,'0')
        bytes += total_length + alphabet_domain
        # bytes
    end

    return bytes.scan(/../).map {|x| x.hex.chr}.join
    # return bytes
end

def build_question(domain, record_type)
    question = ''
    for part in domain
        question += part.length.to_s(16).rjust(2, '0')
        for char in part.split("") do
            question += char.ord.to_s(16)
        end
    end
    question += '00'

    question += get_record_type_hex(record_type)

    question += "0001"

    question = question.scan(/../).map {|m| m.hex.chr}.join

    return question
end


# loop ßdo
    # buf = IO::Buffer.for(socket.recvfrom(512)[0]) 
    recieved = socket.recvfrom(512)

    str = recieved[0].force_encoding('BINARY')

    
    transaction_id = str[0..1]

    flags = get_flags(str[1..3])

    qdcount = binary_string_to_hex('0001')

    records, record_type, domain, asked_record = get_records(str[12..])
   
    asked_records = records[record_type].select {|ele| ele[:name] == asked_record}

    ancount = binary_string_to_hex(asked_records.length.to_s(2).rjust(4,'0'))

    nscount = binary_string_to_hex('0000')

    arcount = binary_string_to_hex('0000')

    questioned_domain = build_question(domain, record_type)

    header = transaction_id + flags + qdcount + ancount + nscount + arcount
    
    dns_body = ''

    for record in asked_records do
        dns_body += record_to_bytes(record_type, record)
    end

    socket.send(
        header + questioned_domain + dns_body, 
        0, 
        recieved[1][3], 
        recieved[1][1]
    )


# end




