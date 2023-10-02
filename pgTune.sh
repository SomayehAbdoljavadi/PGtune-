#!/bin/bash

. ./envPgtune.sh

## Calculate Output Parameters

### ------------ `max_connections`  ---------------------
 
if [ $connections -eq 0 ]
    then
        case $applicationArea in
                'w')
                        connections=200  
                        applicationAreaType="WEB"                                    
                ;;
                'o')
                        connections=300                       
                        applicationAreaType="OTP"
                ;;
                'h')
                        connections=40                       
                        applicationAreaType="Data Warehouse"
                ;;
                'd')
                        connections=20                       
                        applicationAreaType="Desktop"
                ;;
                'm')
                        connections=100                       
                        applicationAreaType="Mixed"                       
                ;;
                *)
                        echo "Sorry, Application Area Must Be One of {w,o,h,d,m}" ;
        esac
        
fi 

### ------------ `ramSize AND ramSizeType `  ---------------------
case $ramType in
                'm')
                        ramSize=$(( ram * 1024 ))
                        ramSizeType="kB"  
                        ramType="MB"  
                        ramSizeKB=$(( ram * 1024 ))         

                ;;
                'g')
                        ramSize=$((ram * 1024))
                        ramSizeType="MB"  
                        ramType="GB"
                        ramSizeKB=$(( ram * 1048576 ))
                        
                ;;
                't')
                        ramSize=$((ram * 1024))
                        ramSizeType="GB" 
                        ramType="TB"
                        ramSizeKB=$(( ram * 1073741824 ))

               ;;
                *)
                        echo "Sorry" ;
        esac
### ------------  shared_buffers AND effective_cache_size ---------------------


if [ $applicationArea == 'd' ] 
        then 
                shared_buffersKB=$((ramSizeKB / 16)) 
                effective_cache_sizeKB=$((ramSizeKB / 4))                             
        else  
                shared_buffersKB=$((ramSizeKB / 4))
                effective_cache_sizeKB=$((ramSizeKB * 3 / 4))
fi

if [[ $((shared_buffersKB/1073741824)) -ge 1 ]]
        then
                shared_buffers=$((shared_buffersKB/1073741824))"TB"
elif [[ $((shared_buffersKB/1048576)) -ge 1 ]]
        then
                shared_buffers=$((shared_buffersKB/1048576))"GB"  
elif [[ $((shared_buffersKB/1024)) -ge 1 ]]
        then
                shared_buffers=$((shared_buffersKB/1024))"MB" 
else
        shared_buffers=$shared_buffersKB"MB" 
fi

if [[ $((effective_cache_sizeKB/1073741824)) -ge 1 ]]
        then
                effective_cache_size=$((effective_cache_sizeKB/1073741824))"TB"
elif [[ $((effective_cache_sizeKB/1048576)) -ge 1 ]]
        then
                effective_cache_size=$((effective_cache_sizeKB/1048576))"GB"  
elif [[ $((effective_cache_sizeKB/1024)) -ge 1 ]]
        then
                effective_cache_size=$((effective_cache_sizeKB/1024))"MB" 
else
        effective_cache_size=$effective_cache_sizeKB"MB" 
fi
### ------------ `maintenance_work_mem`  ---------------------

if [ $applicationArea == 'h' ] 
        then 
               maintenance_work_memkB=$(( ramSizeKB/ 8))              
        else  
               maintenance_work_memKB=$((ramSizeKB/ 16))
fi

if [[ $maintenance_work_memKB -ge 2097152 ]]
        then
                 maintenance_work_mem="2GB" 

        elif [[ $((maintenance_work_memKB/ 1048576)) -ge 1 ]]  
        then
                 maintenance_work_mem=$((maintenance_work_memKB/ 1048576))"GB"       
        
        elif [[ $((maintenance_work_memKB/ 1024)) -ge 1 ]]  
        then
                 maintenance_work_mem=$((maintenance_work_memKB/ 1024))"MB"   
        else
                 maintenance_work_mem=$maintenance_work_memKB"kB"
        
fi

### ------------ checkpoint_segments => min_wal_size AND  max_wal_size ----checkpoint_completion_target-----------------


        case $applicationArea in
                'w')
                        applicationAreaType="Web"              
                        min_wal_size="1GB"
                        max_wal_size="2GB" 
                        checkpoint_completion_target="0.7"
                ;;
                'o')
                        applicationAreaType="OLTP"
                        min_wal_size="2GB"
                        max_wal_size="4GB" 
                        checkpoint_completion_target="0.9"
                ;;
                'h')
                        applicationAreaType="Data Warehouse"
                        min_wal_size="4GB"
                        max_wal_size="8GB" 
                        checkpoint_completion_target="0.9"
                ;;
                'd')
                        applicationAreaType="Desktop"
                        min_wal_size="100MB"
                        max_wal_size="1GB" 
                        checkpoint_completion_target="0.5"
                ;;
                'm')
                        applicationAreaType="Mixed"                                     
                        min_wal_size="1GB"
                        max_wal_size="2GB" 
                        checkpoint_completion_target="0.9"
                ;;
                *)
                        echo "Sorry, Application Area Must Be One of {w,o,h,d,m}" ;
        esac
        
### ------------  wal_buffers  ---------------------

if [ $ramSizeType == "kB" ]
        then
                wal_buffers=$(($shared_buffersKB * 3 / 100)) 
                wal_buffersType="kB"
                if [ $wal_buffers -le 31 ]
                        then
                             wal_buffers=32 
                           
                fi
elif [ $ramSizeType == "MB"  ]
        then
                shared_buffersMB=$(($shared_buffersKB / 1024))
                wal_buffers=$(($shared_buffersMB * 3 / 100)) 
                wal_buffersType="MB"
                if [ $wal_buffers -ge 14 ]
                        then
                             wal_buffers=16          
                fi                  
elif [[ $ramSizeType == "GB" || $ramSizeType == "TB" ]]
        then
                wal_buffers=16  
                wal_buffersType="MB"    
fi




### ------------  default_statistics_target  ---------------------

if [ $applicationArea == 'h' ] 
        then 
                default_statistics_target=500              
        else  
                default_statistics_target=100
fi

### ------------  random_page_cost  ---------------------

if [ $storageTechnology == "hdd" ] 
        then 
                random_page_cost=4              
        else  
                random_page_cost=1.1
fi

### ------------  effective_io_concurrency  ---------------------

case $storageTechnology in
                'hdd')
                        effective_io_concurrency=2           
                ;;
                'ssd')
                        effective_io_concurrency=200
                ;;
                'san')
                        effective_io_concurrency=300
               ;;
                *)
                        echo "Sorry, Storage Must Be One of {hdd,ssd,san}" ;
        esac

### ------------  max_worker_processes  ---------------------
if [ $postgreSqlVersion -ge 9 ]
    then
        max_worker_processes=$numberOfCpuCores
fi
### ------------  max_parallel_workers_per_gather  ---------------------
if [ $postgreSqlVersion -ge 9 ]
    then
        max_parallel_workers_per_gather=$(($numberOfCpuCores / 2))
fi
### ------------  max_parallel_workers  ---------------------
if [ $postgreSqlVersion -ge 10 ]
    then
        max_parallel_workers=$numberOfCpuCores
fi

### ------------  work_mem  ---------------------
ramSizeKB_sharedBuffersKB=$(($ramSizeKB - $shared_buffersKB))
ramSizeKB_sharedBuffersKB=${ramSizeKB_sharedBuffersKB##*[+-]}
workMemValue=$(($ramSizeKB_sharedBuffersKB / $((3 * $connections))/ $max_parallel_workers_per_gather ))

case $applicationArea in
                'w')
                        work_mem=$workMemValue                                      
                ;;
                'o')
                        work_mem=$workMemValue                      
                ;;
                'h')
                        work_mem=$(($workMemValue / 2 ))
                ;;
                'd')
                        work_mem=$(($workMemValue / 6))      
                ;;
                'm')
                        work_mem=$(($workMemValue / 2 ))                      
                ;;
                *)
                        echo "Sorry, Application Area Must Be One of {w,o,h,d,m}" ;
        esac
         
        if [[ $work_mem -le 64 && $ramSizeType == "kB" ]]
                then
                        work_mem="64kB"
        fi 

### ------------  OutPut  ---------------------

. ./env.sh;echo -n $pg_cluster
cat <<EOF >  /etc/postgresql/${postgreSqlVersion}/${pg_cluster}/conf.d/config.conf
  #PostgreSQL-Version: $postgreSqlVersion 
  #OS : $operatingSystem 
  #Application: $applicationAreaType
  #Memory: $ram $ramType 
  #Cores: $numberOfCpuCores 
  #Connections: $connections 
  #Storage: $storageTechnology 

 max_connections = $connections 
 shared_buffers = $shared_buffers 
 effective_cache_size = $effective_cache_size 
 maintenance_work_mem = $maintenance_work_mem 
 checkpoint_completion_target = $checkpoint_completion_target 
 wal_buffers = $wal_buffers$wal_buffersType 
 default_statistics_target = $default_statistics_target 
 random_page_cost =  $random_page_cost
 effective_io_concurrency = $effective_io_concurrency
 work_mem = ${work_mem}kB
 min_wal_size = $min_wal_size
 max_wal_size = $max_wal_size
 max_worker_processes = $max_worker_processes
 max_parallel_workers_per_gather = $max_parallel_workers_per_gather
 max_parallel_workers = $max_parallel_workers
EOF
