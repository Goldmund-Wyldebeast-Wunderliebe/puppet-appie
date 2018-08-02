class appie::packages::mayan (
) {
    package { [
            'g++', 'gcc', 'ghostscript', 'gnupg1', 'graphviz', 'libjpeg-dev',
            'libmagic1', 'libpq-dev', 'libpng-dev', 'libreoffice',
            'libtiff5-dev', 'poppler-utils', 'postgresql', 'python-dev',
            'python-pip', 'python-virtualenv', 'redis-server', 'sane-utils',
            'supervisor', 'tesseract-ocr', 'zlib1g-dev',
            'tesseract-ocr-all',
        ]: ensure => installed
    }
}
