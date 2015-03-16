function [ feats ] = densetraj_select_features( descriptor, max_features )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	set_env;
	
	% parameters
	if ~exist('max_features', 'var'),
		max_features = 50000;
	end
	
	%% event_set = 1: 10ex, 2:100Ex, 3: 130Ex
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %d)', mfilename, descriptor, max_features);
	logmsg(logfile, msg);
	
	tic;
	
	%video_sampling_rate = 1;
	%sample_length = 120; % frames
	%ensure_coef = 1.1;
	
	 %% TODO: using unified metadata
	% f_metadata = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/common/metadata_devel.mat';
	%f_metadata = '/home/ntrang/projects/output/hmdb51_2014_brush_hair.info.mat';
	f_metadata = '/home/ntrang/project/output/hmdb51/metadata/metadata.mat';
	
	fprintf('Loading metadata...\n');
	load(f_metadata, 'metadata');
   
	% video_dir = '/net/per610a/export/das11f/plsang/dataset/MED2013/LDCDIST-RSZ';
	video_dir = '/home/ntrang/project/dataset/hmdb51/';
		
	%fprintf('Loading metadata...\n');
	% medmd_file = '/net/per610a/export/das11f/plsang/trecvidmed13/metadata/medmd.mat';
	%medmd_file = '/home/ntrang/projects/output/hmdb51_2014_01_test.info.mat';
	%load(medmd_file, 'MEDMD'); 
	
	%clips = MEDMD.EventBG.default.clips;
	%list_video = unique(clips);	% 4992 clips
	
	%num_selected_videos = ceil(video_sampling_rate * length( list_video ));
	%rand_index = randperm(length(list_video));
	%selected_index = rand_index(1:num_selected_videos);
	%selected_videos = list_video(selected_index);
	
	
	%max_features_per_video = ceil(ensure_coef*max_features/length(selected_videos));
	max_features_per_video = 1000;
	%feats = cell(length(selected_videos), 1);
	%selected_videos = dir(video_dir);
	%parfor ii = 1:length(selected_videos),
	ii = 1;
	for i = 1:length(metadata.videos),
		event_name = metadata.events{i};
		video_name = metadata.videos{i};
		label = metadata.labels{i};
		
		if label == 2, %if video is used for testing, ignore it
			continue;
		end
		
		video_file = sprintf('%s/%s/%s.avi', video_dir, event_name, video_name);
		%start_frame = 1;
		%end_frame = 100;

		%if end_frame - start_frame < 15,
		%	continue;
		%end

		%if end_frame - start_frame > sample_length,
		%	start_frame = start_frame + randi(end_frame - start_frame - sample_length);
		%	end_frame = start_frame + sample_length;
		%end

		fprintf('\n--- [%d/%d] Computing features for video %s ...\n', i, length(metadata.videos), video_name);

		feat = densetraj_extract_features(video_file, descriptor);

		if size(feat, 2) > max_features_per_video,
			feats{ii} = vl_colsubset(feat, max_features_per_video);
		else
			feats{ii} = feat;
		end
		ii = ii + 1;
	end
	
	% trangnt-_-
	% concatenate features into a single matrix
	feats = cat(2, feats{:});
	
	if size(feats, 2) > max_features,
		 feats = vl_colsubset(feats, max_features);
	end

	output_file = sprintf('/home/ntrang/project/output/hmdb51/feature/bow.codebook.devel/idensetraj.%s/data/selected_feats_%d.mat', descriptor, max_features);
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		cmd = sprintf('mkdir -p %s', output_dir);
		system(cmd);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
	save(output_file, 'feats', '-v7.3');
   
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	
	msg = sprintf('Finish running %s(%s, %d). Elapsed time: %s', mfilename, descriptor, max_features, elapsed_str);
	logmsg(logfile, msg);
end

