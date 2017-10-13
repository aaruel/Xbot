import React from 'react'
import Head from 'next/head'
import {
    App,
    Article,
    Box,
    Columns,
    Image,
    Tip,
    Title,
    Video,
    Split,
    Value
} from 'grommet'
import CaretUpIcon from 'grommet/components/icons/base/CaretUp';
import CaretDownIcon from 'grommet/components/icons/base/CaretDown';
import Pulse from 'grommet/components/icons/Pulse'

const Header = () => (
    <Head>
        <title>ME Leaderboard</title>
        <link rel="stylesheet" type="text/css" href="https://rawgit.com/grommet/grommet/stable/grommet.min.css" />
        <link rel="stylesheet" type="text/css" href="/static/custom.css" />
    </Head>
)

const Score = (props) => {
    return (
        <Box align="center">
            <CaretUpIcon colorIndex="ok" />

            <Value responsive={true}
                value={props.score}
                size="small"
                align="start"/>

            <CaretDownIcon colorIndex="critical" />
        </Box>
    )
}

const User = (props) => {
    return (
        <Box direction="row">
            <Box align="center">
                {(/discord/.test(props.content))
                    ? <Image src={props.content} fit="contain"/>
                    : <iframe id="ytplayer" type="text/html" width="640" height="360" src={props.content} frameBorder="0" />}
            </Box>
            <Box alignSelf="end">
                {props.username}
            </Box>
        </Box>
    )
}

class Post extends React.Component {
    constructor(props) {
        super(props);

        this.state = {};
    }

    render() {
        return (
        <Box align="center"
            alignSelf="center"
            pad="small"
            flex={true}
            margin="small"
            colorIndex="light-2"
            separator="left"
            size={{height: "auto"}}
            justify="center">

            <Box alignSelf="start" responsive={false} direction="row" pad={{between: "medium"}}>
                <Score score={this.props.data.score} />
                <User content={this.props.data.content} username={this.props.data.username} />
            </Box>

        </Box>)
    }
}

const Main = (props) => {
    return (
        <Box announce={false}
            direction="column"
            focusable={true}
            primary={true}
            pad={{horizontal: "large"}}
            responsive={true}
            tag="div">
            {props.children}
        </Box>
    )
}

class Index extends React.Component {
    constructor(props) {
        super(props);

        this.state = {posts: [0], page: 1};
    }

    async setPage(page) {
        const _data = await fetch(`http://localhost:3030/${page}`)
        const data = await _data.json()

        const getContent = (d) => {
            if (d[1].length) return d[1][0].url
            else return d[2]
        }

        const getScore = (d) => {
            const sum = d[4].map(n => {
                if (n.emoji.name == "upvote") {
                    return n.count;
                }
                else if (n.emoji.name == "downvote") {
                    return -n.count;
                }
                else {
                    return 0;
                }
            });
            return sum.reduce((total, currentValue) => total+currentValue, 0)
        }

        const sorter = (a, b) => {
            if (a.score < b.score) return 1;
            if (a.score > b.score) return -1;
            return 0;
        }

        const setWebSockets = () => {
            if (!window.ws) {
                window.ws = new WebSocket("ws://localhost:3030/ws")
            }
            ws.onopen = () => {
                ws.send("connected...");
                console.log("%c" + "Socket Connected", "color:Green");
            }

            ws.onmessage = (e) => {
                window.message = JSON.parse(e.data)
                const pars = {
                    id: message[0],
                    content: getContent(message),
                    username: message[3]["username"],
                    score: getScore(message)
                }
                if (pars.id) {
                    var modified = false;
                    const mapped = this.state.posts.map((d) => {
                        if (d.id == pars.id) {
                            modified = true;
                            return pars;
                        }
                        else {
                            return d;
                        }
                    });
                    if (!modified) {
                        this.setState({posts: mapped.concat(pars).sort(sorter).slice(0, 10)})
                    }
                    else {
                        this.setState({posts: mapped.sort(sorter)})
                    }
                }
            }
        }
        setWebSockets()

        const sorted = data.map(d => {
            return {
                id: d[0],
                content: getContent(d),
                username: d[3]["username"],
                score: getScore(d)
            }
        }).sort(sorter)
        this.setState({posts: sorted, page: page})
    }

    async componentDidMount() {
        this.setPage(this.state.page)
    }

    render() {
        const pageSelector = () => (
            <Box direction="row" colorIndex="accent-1">
                Page {this.state.page}
                {this.state.page != 1
                    ? <a onClick={() => {
                        this.setPage.bind(this)(this.state.page-1)
                        window.scrollTo(0, 0)
                    }}>Previous Page</a>
                    : null}
                {this.state.posts.length == 10
                    ? <a onClick={() => {
                        this.setPage.bind(this)(this.state.page+1)
                        window.scrollTo(0, 0)
                    }}>Next Page</a>
                    : null}
            </Box>
        )

        return (
            <div>
                <Header />
                <App>
                <Main>
                    <Columns justify="start"
                        maxCount={1}
                        responsive={true}>
                        <Title> ME Leaderboard</Title>
                    </Columns>

                    {pageSelector()}

                    {this.state.posts.map(v => <Post data={v} key={v.id} />)}

                    {pageSelector()}
                </Main>
                </App>
            </div>
        )
    }
}

export default () => (<Index />)
