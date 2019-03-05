directory = '/Users/sding/Desktop/maskedTiffs/';
tiffList = dirSearch(directory,'.tif');
framesPerStack = 32400;
for stackCtr = 1
    tiffStackName = [directory 'stack' num2str(stackCtr) '_rescaledFull.tif'];
    startFrame = framesPerStack*(stackCtr-1)+1;
    endFrame = framesPerStack*stackCtr;
    if endFrame>32400
        endFrame = 32400;
    end
    for frameCtr = startFrame:endFrame
        [frameCtr/framesPerStack stackCtr]
        img = imread(tiffList{frameCtr});
        img = uint8(double(img)/65535*255);
        imwrite(img,tiffStackName, 'WriteMode','append','Compression','lzw');
    end
end