module.exports = {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        bk: {
          /* backgrounds */
          bg:       '#07090D',
          surface:  '#0C1018',
          card:     '#111720',
          elevated: '#182030',
          /* borders */
          border:   '#1E2B3C',
          'border-2': '#253347',
          /* yellow accent */
          yellow:       '#F5C518',
          'yellow-hover': '#DEB214',
          'yellow-dim':   'rgba(245,197,24,0.10)',
          /* text */
          text:   '#DDE4EE',
          'text-2': '#6E8099',
          'text-3': '#3A4F65',
          /* event types */
          buy:      '#00C896',
          sell:     '#FF4D6D',
          dividend: '#4B9EFF',
          earnings: '#FF8C42',
          rebalance:'#9B72F4',
          watch:    '#22D4F5',
        },
      },
      fontFamily: {
        sans: [
          'Pretendard Variable',
          'Pretendard',
          '-apple-system',
          'BlinkMacSystemFont',
          'sans-serif',
        ],
        mono: ['JetBrains Mono', 'Fira Code', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        xs:   ['13px', { lineHeight: '1.5' }],
        sm:   ['15px', { lineHeight: '1.5' }],
        base: ['17px', { lineHeight: '1.65' }],
        lg:   ['19px', { lineHeight: '1.5' }],
        xl:   ['22px', { lineHeight: '1.4' }],
        '2xl':['26px', { lineHeight: '1.3' }],
        '3xl':['32px', { lineHeight: '1.2' }],
      },
      borderRadius: {
        none: '0px',
        sm:   '2px',
        DEFAULT: '4px',
        md:   '6px',
        lg:   '8px',
      },
    },
  },
  plugins: [],
};
