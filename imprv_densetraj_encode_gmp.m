function imprv_densetraj_encode_gmp(descriptor, kernel, index)
	% encoding method: fisher vector
	% representation: video-based, (can be extended to segment level)
	% power normalization, which one is the best? alpha = 0.2? 
	
	% setting
	set_env;
	dimred = 128;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s', mfilename);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;

	if ~exist('kernel', 'var'),
		kernel = 'linear';
	end

	if ~exist('index', 'var'),
		index = 1;
	end
	
	switch descriptor,
		case 'hoghof'
			start_idx = 41;
			end_idx = 244;
		case 'mbh'
			start_idx = 245;
			end_idx = 436;
		case 'hoghofmbh'
			start_idx = 41;
			end_idx = 436;
		otherwise
			error('Unknown descriptor for dense trajectories!!\n');
	end
	
	feat_dim = end_idx - start_idx + 1;
	
	video_dir = '/home/ntrang/project/dataset/hmdb51';
	fea_dir = '/home/ntrang/project/output/hmdb51/feature';
	
	f_metadata = sprintf('/home/ntrang/project/output/hmdb51/metadata/metadata.mat');  % for kinddevel only
	
	fprintf('Loading basic metadata...\n');
	metadata = load(f_metadata, 'metadata');
	metadata = metadata.metadata;
	
	codebook_gmm_size = 256; %cluster_count

	feature_ext_fc = sprintf('imprvdensetraj.%s.%s.cb%d.fc', descriptor, kernel, codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('imprvdensetraj.%s.%s.cb%d.fc.pca', descriptor, kernel, codebook_gmm_size);
	end

	output_dir_fc = sprintf('%s/%s', fea_dir, feature_ext_fc);
	
	if ~exist(output_dir_fc, 'file'),
		mkdir(output_dir_fc);
		change_perm(output_dir_fc);
	end
	
	% loading gmm codebook
	codebook_file = sprintf('/home/ntrang/project/output/hmdb51/feature/bow.codebook.devel/imprvdensetraj.%s/data/codebook.gmm.%d.%d.mat', descriptor, codebook_gmm_size, dimred);
	low_proj_file = sprintf('/home/ntrang/project/output/hmdb51/feature/bow.codebook.devel/imprvdensetraj.%s/data/lowproj.%d.%d.mat', descriptor, dimred, feat_dim);
	codebook_ = load(codebook_file, 'codebook');
	codebook = codebook_.codebook;
	
	low_proj_ = load(low_proj_file, 'low_proj');
	low_proj = low_proj_.low_proj;
	
	samples = [48,18,44,51,46,45,21,9,33,7];
	for i = index:length(metadata.videos),
		event_name = metadata.events{i};
		video_name = metadata.videos{i};
		classid = metadata.classids(i);
		
		video_file = sprintf('%s/%s/%s.avi', video_dir, event_name, video_name);
		
		output_file = sprintf('%s/%s/%s.mat', output_dir_fc, event_name, video_name);
		
		if exist(output_file, 'file'),
			fprintf('File [%s] already exist. Skipped!!\n', output_file);
			continue;
		end
		
		if isempty(find(samples == classid)),
			fprintf('[%s] belongs to [%s] is not in samples, ignore!!\n', video_name, event_name);
			continue;
		end
		
		fprintf(' [%d] Extracting & Encoding for [%s]\n', i, video_name);
		
		code = imprv_densetraj_gmp_extract_and_encode(descriptor, kernel, video_file, codebook, low_proj); %important
		
		%%% trong hàm imprv_densetraj_gmp_extract_and_encode đã dùng power norm rồi, sao còn dùng ở đây nữa?!
		% power normalization (with alpha = 0.5)
		code = sign(code) .* sqrt(abs(code));
		
		
		
		elapsed = toc;
		elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
		fprintf('Finish running %s. Elapsed time: %s\n', video_name, elapsed_str);
		par_save(output_file, code, 1); 

	end
	
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s. Elapsed time: %s', mfilename, elapsed_str);
	logmsg(logfile, msg);
end

