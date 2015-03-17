require 'json'
require 'optparse'
#Pass -m for machine readable
params = ARGV.getopts("m")

def billing_tier (cpu, memory)
    numeric_tier = Array.new
    numeric_tier[0] = 'micro'
    numeric_tier[1] = 'tiny'
    numeric_tier[2] = 'small'
    numeric_tier[3] = 'medium'
    numeric_tier[4] = 'medium_high_memory'
    numeric_tier[5] = 'large'
    numeric_tier[6] = 'large_high_memory'
    numeric_tier[7] = 'tier_1_small'
    numeric_tier[8] = 'tier_1_medium'
    numeric_tier[9] = 'tier_1_large'
    #Sizes:
    if (memory >= 0.5*1024) then memsize=0 end
    if (memory >= 2*1024)   then memsize=1 end
    if (memory >= 4*1024)   then memsize=2 end
    if (memory >= 8*1024)   then memsize=3 end
    if (memory >= 16*1024)  then memsize=4 end
    if (memory >= 32*1024)  then memsize=6 end
    if (memory >= 48*1024)  then memsize=7 end
    if (memory >= 64*1024)  then memsize=8 end
    if (memory >= 96*1024)  then memsize=9 end
    if (cpu >= 1) then cpusize=0 end
    if (cpu >= 2) then cpusize=2 end
    if (cpu >= 4) then cpusize=3 end
    if (cpu >= 8) then cpusize=5 end

    if (cpusize > memsize) then
        tier=numeric_tier[cpusize]
    else
        tier=numeric_tier[memsize]
    end
    return tier
end

def hourly_price (cpu, memory, vdc)
    cpu = cpu.split(' ').first.to_i
    memory = memory.split(' ').first.to_i
    #Pricing is based on tiers of VM - you pay for the cheapest tier that meets you CPU/RAM requirement
    skyscape = Hash.new
    tier = vdc.scan(/\((.*)\)/).last.first
    skyscape['IL2-DEVTEST-BASIC'] = {
        'micro'                 => 0.03,
        'tiny'                  => 0.07,
        'small'                 => 0.09,
        'medium'                => 0.15,
        'medium_high_memory'    => 0.28,
        'large'                 => 0.29,
        'large_high_memory'     => 0.53,
        'tier_1_small'          => 0.71,
        'tier_1_medium'         => 0.89,
        'tier_1_large'          => 1.25,
    }
    skyscape['IL2-PROD-STANDARD'] =  {
        'micro'                 => 0.06,
        'tiny'                  => 0.16,
        'small'                 => 0.21,
        'medium'                => 0.37,
        'medium_high_memory'    => 0.53,
        'large'                 => 0.76,
        'large_high_memory'     => 1.23,
        'tier_1_small'          => 1.70,
        'tier_1_medium'         => 2.16,
        'tier_1_large'          => 3.10,
    }
    size = billing_tier(cpu, memory)
    return skyscape[tier][size]
end
def right_size (cpu, memory)
    cpu = cpu.split(' ').first.to_i
    memory = memory.split(' ').first.to_i
    paysize = billing_tier(cpu, memory)
    if (cpu >= 1 && memory >= 0.5*1024) then usesize='micro' end
    if (cpu >= 1 && memory >= 2*1024)   then usesize='tiny' end
    if (cpu >= 2 && memory >= 4*1024)   then usesize='small' end
    if (cpu >= 4 && memory >= 8*1024)   then usesize='medium' end
    if (cpu >= 4 && memory >= 16*1024)  then usesize='medium_high_memory' end
    if (cpu >= 8 && memory >= 16*1024)  then usesize='large' end
    if (cpu >= 8 && memory >= 32*1024)  then usesize='large_high_memory' end
    if (cpu >= 8 && memory >= 48*1024)  then usesize='tier_1_small' end
    if (cpu >= 8 && memory >= 64*1024)  then usesize='tier_1_medium' end
    if (cpu >= 8 && memory >= 96*1024)  then usesize='tier_1_large' end

    if (paysize == usesize) then
        return "Correct (#{paysize})"
    else
        return "INCORRECT - Paying for (#{paysize})"
    end
end


p "All prices listed assume storage and compute are for 730 hours/month"
total_cost = 0
json=File.read('./organization.json')
foo = JSON.parse(json)
foo['vdcs'].each do |vdc|
  env_cost=0
  if params['m'] then
    print  "#{vdc['name']} "
  else
    print  "#{vdc['name']}\n"
  end
  vdc['vapps'].each do |vapp|
    vapp['vms'].each do |vm|
      if vm['status'] != "8" then
        monthly_cost = (hourly_price(vm['cpu'], vm['memory'], vdc['name']) * 730).round(2)
        size_check = right_size(vm['cpu'], vm['memory'])
        env_cost = env_cost + monthly_cost
        print "vApp: #{vapp['name']} #{vm['cpu']} #{vm['memory']} #{vm['disks'][0]['size']} - Price/month: £#{monthly_cost} - VM Tier: #{size_check}\n" unless params['m']
      end
    end
  end
  if params['m'] then
      puts ":#{env_cost.round(2)}"
  else
    puts "Env cost: £#{env_cost.round(2)}"
  end
  total_cost = total_cost + env_cost
end
  if params['m'] then
      puts "TOTAL:#{total_cost.round(2)}"
  else
    puts "Total cost: £#{total_cost.round(2)}"
  end
