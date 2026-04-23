function copy_figure(figurelist,sourcefolder,destinationfolder,foldername)

mkdir(destinationfolder,foldername)
for i=1:length(figurelist)
    status = copyfile(strcat(sourcefolder,'\',figurelist{i}),strcat(destinationfolder,'\',foldername));
    if status==0
        error(['File ',figurelist{i}, ' not found'])
    end
end