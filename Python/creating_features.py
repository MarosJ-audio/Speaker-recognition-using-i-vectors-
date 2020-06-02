import os
import sidekit
import numpy as np
import logging
logging.basicConfig(level=logging.INFO)
from multiprocessing import cpu_count
from utils import parse_yaml

class FeaturesExtractor():

    def __init__(self, conf_path):
        #parse the YAML configuration file
        self.conf = parse_yaml(conf_path)
        self.audio_dir = os.path.join(self.conf['outpath'], "audio") #input dir
        self.feat_dir = os.path.join(self.conf['outpath'], "feat")
        # Number of parallel threads
        self.NUM_THREADS = cpu_count()

        self.FEAUTRES = self.conf['features']
        self.FILTER_BANK = self.conf['filter_bank']
        self.FILTER_BANK_SIZE = self.conf['filter_bank_size']
        self.LOWER_FREQUENCY = self.conf['lower_frequency']
        self.HIGHER_FREQUENCY = self.conf['higher_frequency']
        self.VAD = self.conf['vad']
        self.SNR_RATIO = self.conf['snr_ratio'] if self.VAD=="snr" else None
        # cepstral coefficients
        self.WINDOW_SIZE = self.conf['window_size']
        self.WINDOW_SHIFT = self.conf['window_shift']
        self.CEPS_NUMBER = self.conf['cepstral_coefficients']
        # reset unnecessary ones based on given configuration
        self.review_member_variables()


    def review_member_variables(self):
        # Review fb
        if "fb" not in self.FEAUTRES:
            self.FILTER_BANK      = None
            self.FILTER_BANK_SIZE = None
            self.LOWER_FREQUENCY  = None
            self.HIGHER_FREQUENCY = None

        # Review cep
        if "cep" not in self.FEAUTRES:
            self.WINDOW_SIZE = None
            self.WINDOW_SHIFT = None
            self.CEPS_NUMBER = None
        
        # Review vad
        if "vad" not in self.FEAUTRES:
            self.VAD = None
            self.SNR_RATIO = None


    def extract_features(self, group):
        assert group in ["enroll", "test"],\
            "Invalid group name!! Choose either 'enroll', 'test'"
        in_files = os.listdir(os.path.join(self.audio_dir, group))
        feat_dir = os.path.join(self.feat_dir, group)

        extractor = sidekit.FeaturesExtractor(
            audio_filename_structure=os.path.join(self.audio_dir, group, "{}"),
            feature_filename_structure=os.path.join(feat_dir, "{}.h5"),
            lower_frequency=self.LOWER_FREQUENCY,
            higher_frequency=self.HIGHER_FREQUENCY,
            filter_bank=self.FILTER_BANK,
            filter_bank_size=self.FILTER_BANK_SIZE,
            window_size=self.WINDOW_SIZE,
            shift=self.WINDOW_SHIFT,
            ceps_number=self.CEPS_NUMBER,
            vad=self.VAD,
            snr=self.SNR_RATIO,
            save_param=self.FEAUTRES,
            keep_all_features=True)


        show_list = np.unique(np.hstack([in_files]))
        channel_list = np.zeros_like(show_list, dtype = int)

        SKIPPED = []
        for show, channel in zip(show_list, channel_list):
            try:
                extractor.save(show, channel)
            except RuntimeError:
                logging.info("SKIPPED")
                SKIPPED.append(show)
                continue
        logging.info("Number of skipped files: "+str(len(SKIPPED)))
        for show in SKIPPED:
            logging.debug(show)

if __name__ == "__main__":
    conf_filename = "conf.yaml"
    ex = FeaturesExtractor(conf_filename)
    ex.extract_features("enroll")
    ex.extract_features("test")