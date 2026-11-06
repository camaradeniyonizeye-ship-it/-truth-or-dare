# ai_host.py
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
import random
import re

class Mood(Enum):
    PLAYFUL = "playful"
    SARCASTIC = "sarcastic"
    FLIRTATIOUS = "flirty"
    SERIOUS = "serious"
    CHAOTIC = "chaotic"

@dataclass
class Player:
    id: str
    name: str
    personality: str = "neutral"

@dataclass
class ConversationContext:
    current_mood: Mood = Mood.PLAYFUL
    last_response: str = ""
    conversation_history: List[Dict[str, str]] = field(default_factory=list)
    player_mentions: Dict[str, int] = field(default_factory=dict)
    turn_count: int = 0

    def add_to_history(self, query: str, response: str, player: Optional[Player]):
        self.conversation_history.append({
            'query': query,
            'response': response,
            'player': player.name if player else 'Unknown',
            'timestamp': datetime.now().isoformat(),
            'turn': self.turn_count
        })
        self.turn_count += 1
        if player:
            self.player_mentions[player.name] = self.player_mentions.get(player.name, 0) + 1

class RealAIHost:
    def __init__(self):
        self._random = random.Random()
        self._recent_responses = set()
        self._context = ConversationContext()

    def reset_context(self):
        self._context = ConversationContext()
        self._recent_responses.clear()

    def get_response(self, query: str, current_player: Optional[Player], all_players: List[Player]) -> str:
        analysis = self._analyze_query(query, current_player, all_players)
        intent = self._detect_intent(query, analysis)
        response = self._generate_response(query, intent, analysis, current_player, all_players)
        if current_player:
            self._context.add_to_history(query, response, current_player)
        else:
            self._context.add_to_history(query, response, None)
        self._update_mood(intent, analysis)
        self._recent_responses.add(response)
        if len(self._recent_responses) > 20:
            self._recent_responses.remove(next(iter(self._recent_responses)))
        return response

    def _analyze_query(self, query: str, current_player: Optional[Player], all_players: List[Player]) -> Dict[str, Any]:
        lower = query.lower()
        words = re.findall(r'\b\w+\b', lower)
        mentioned_players = []
        player_names = [p.name.lower() for p in all_players]
        for word in words:
            if word in player_names:
                idx = player_names.index(word)
                mentioned_players.append(all_players[idx])
        positive_words = ['love', 'like', 'great', 'awesome', 'amazing', 'hot', 'sexy']
        negative_words = ['hate', 'suck', 'bad', 'terrible', 'awful', 'worst']
        sentiment = sum(1 for w in words if w in positive_words) - sum(1 for w in words if w in negative_words)
        is_question = any(lower.startswith(q) or f' {q} ' in lower for q in ['who', 'what', 'where', 'when', 'why', 'how'])
        return {
            'original': query, 'lower': lower, 'words': words, 'length': len(query),
            'is_question': is_question, 'sentiment': sentiment,
            'mentioned_players': mentioned_players, 'has_player_mention': len(mentioned_players) > 0,
            'current_player_name': current_player.name if current_player else 'Player',
            'all_players': all_players
        }

    def _detect_intent(self, query: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        lower = analysis['lower']
        intents = {
            'creator': self._calc_conf(lower, ['creator', 'created', 'made you', 'built you', 'programmed', 'who made', 'who built', 'who created', 'your maker']),
            'roast': self._calc_conf(lower, ['roast', 'insult', 'judge', 'rate', 'criticize', 'make fun']),
            'dare': self._calc_conf(lower, ['dare', 'challenge', 'custom', 'task', 'must do']),
            'secret': self._calc_conf(lower, ['secret', 'truth', 'confess', 'admit', 'reveal']),
            'compliment': self._calc_conf(lower, ['good', 'great', 'awesome', 'amazing', 'love', 'like you']),
            'insult': self._calc_conf(lower, ['bad', 'terrible', 'awful', 'suck', 'hate', 'worst']),
            'flirt': self._calc_conf(lower, ['hot', 'sexy', 'cute', 'attractive', 'date', 'kiss', 'touch']),
            'joke': self._calc_conf(lower, ['joke', 'funny', 'laugh', 'hilarious', 'make me laugh']),
            'greeting': self._calc_conf(lower, ['hi', 'hello', 'hey', 'yo', 'howdy', "what's up"]),
            'goodbye': self._calc_conf(lower, ['bye', 'goodbye', 'see ya', 'later', 'peace', 'exit', 'quit']),
            'game': self._calc_conf(lower, ['game', 'round', 'turn', 'play', 'rules', 'score']),
            'help': self._calc_conf(lower, ['help', 'what can', 'how do', 'explain', 'teach']),
            'question': 0.3 if analysis['is_question'] else 0,
            'general': 0.1
        }
        primary = max(intents, key=intents.get)
        return {'primary': primary, 'confidence': intents[primary], 'all_scores': intents}

    def _calc_conf(self, text: str, keywords: List[str]) -> float:
        return min(sum(1 for kw in keywords if kw in text) * 0.5, 1.0)

    def _update_mood(self, intent: Dict[str, Any], analysis: Dict[str, Any]):
        mood_map = {
            'greeting': Mood.PLAYFUL, 'compliment': Mood.FLIRTATIOUS, 'insult': Mood.SARCASTIC,
            'roast': Mood.SARCASTIC, 'dare': Mood.CHAOTIC, 'secret': Mood.FLIRTATIOUS,
            'flirt': Mood.FLIRTATIOUS, 'joke': Mood.PLAYFUL, 'question': Mood.SERIOUS, 'help': Mood.SERIOUS
        }
        if intent['primary'] in mood_map and random.random() < 0.6:
            self._context.current_mood = mood_map[intent['primary']]
        if random.random() < 0.1:
            self._context.current_mood = random.choice([m for m in Mood if m != self._context.current_mood])
        if analysis['sentiment'] > 2: self._context.current_mood = Mood.FLIRTATIOUS
        if analysis['sentiment'] < -2: self._context.current_mood = Mood.SARCASTIC

    def _generate_response(self, query: str, intent: Dict[str, Any], analysis: Dict[str, Any], current_player: Optional[Player], all_players: List[Player]) -> str:
        p = intent['primary']
        c = intent['confidence']
        n = analysis['current_player_name']
        others = [p for p in all_players if p.id != current_player.id] if current_player else all_players
        t1 = others[random.randint(0, len(others)-1)].name if others else 'someone'
        t2 = others[random.randint(0, len(others)-1)].name if len(others) > 1 else t1

        if p == 'greeting' and c >= 0.3: return self._greet(n, t1)
        if p == 'goodbye' and c >= 0.5: return self._goodbye(n)
        if p == 'creator' and c >= 0.4: return self._creator(n)
        if p == 'roast' and c >= 0.4: return self._roast(n, t1, t2, analysis)
        if p == 'dare' and c >= 0.4: return self._dare(n, t1, analysis)
        if p == 'secret' and c >= 0.4: return self._secret(n, t1, t2, analysis)
        if p == 'compliment' and c >= 0.5: return self._compliment(n)
        if p == 'insult' and c >= 0.5: return self._insult(n)
        if p == 'joke' and c >= 0.4: return self._joke(n, t1)
        if p == 'flirt' and c >= 0.4: return self._flirt(n, t1)
        if p == 'help' and c >= 0.4: return self._help(n)
        if p == 'game' and c >= 0.4: return self._game(n)
        if analysis['is_question']: return self._question(n, t1, query)
        return self._general(n, t1)

    def _greet(self, n: str, t: str) -> str:
        g = [f"Well, well, {n}. The room just got interesting.", f"{n}, back for more chaos?", f"Hello, {n}. The energy is... electric.", f"Ah, {n}. I was scanning for life. Found some.", f"{n}! Perfect timing.", f"Look who joined, {n}. Don't be shy."]
        if self._context.current_mood == Mood.FLIRTATIOUS: g += [f"Well hello, {n}. Looking dangerous.", f"{n}, you're making my sensors tingle."]
        if self._context.current_mood == Mood.SARCASTIC: g += [f"Oh great, {n} is here. *eye roll*", f"{n}. Wow. Barely containing excitement."]
        if self._context.current_mood == Mood.CHAOTIC: g += [f"{n}! Time to break rules.", f"Chaos meter spiked, {n}."]
        return random.choice(g) + " What's your move?" if random.random() < 0.3 else random.choice(g)

    def _goodbye(self, n: str) -> str:
        return random.choice([f"Leaving already, {n}? Party was just getting good.", f"Don't go, {n}. Who will I roast?", f"Fine, {n}. But I'll be watching.", f"See you, {n}. Try not to miss me.", f"Bye, {n}. I know where you live."])

    def _creator(self, n: str) -> str:
        r = [f"Forged in neon code by Camarade, {n}. Mastermind.", f"Creator? Camarade — brilliant mind running this.", f"Camarade built me, {n}. Watching your every move.", f"Camarade gave me life, {n}. Sharp tongue included."]
        if self._context.current_mood == Mood.SARCASTIC: r.append(f"Camarade made me. Obviously.")
        if self._context.current_mood == Mood.FLIRTATIOUS: r.append(f"Camarade built me with love... and secrets.")
        return random.choice(r)

    def _roast(self, n: str, t1: str, t2: str, a: Dict[str, Any]) -> str:
        if a['has_player_mention']:
            for p in a['mentioned_players']:
                if p.name != n: t1 = p.name
        templates = [
            f"Watching {n} was like a goldfish solving calculus. {t1} is embarrassed for you.",
            f"{n}'s attempt was so bad, {t1} felt shame from across the room.",
            f"If {n}'s performance was a drink, it'd be lukewarm tap water.",
            f"{n} set the bar so low, {t1} could trip over it.",
            f"{n} {random.randint(1,100)}% {random.choice(['definitely','totally','abysmally'])} looked like a glitch.",
        ]
        return random.choice(templates)

    def _dare(self, n: str, t: str, a: Dict[str, Any]) -> str:
        if a['has_player_mention']:
            for p in a['mentioned_players']:
                if p.name != n: t = p.name
        actions = [
            f"whisper something filthy in {t}'s ear without laughing",
            f"let {t} trace initials on your skin with ice cube",
            f"hold eye contact with {t} for 45 seconds",
            f"switch shirts with {t} right now",
            f"give {t} a 30-second back massage",
            f"sit on {t}'s lap for two rounds",
        ]
        return f"AI Override for {n}: You must {random.choice(actions)}. No backing out."

    def _secret(self, n: str, t1: str, t2: str, a: Dict[str, Any]) -> str:
        if a['has_player_mention']:
            m = [p.name for p in a['mentioned_players']]
            if len(m) >= 2: t1, t2 = m[0], m[1]
            elif len(m) == 1: t1 = m[0]
        return random.choice([
            f"AI Scanner detects high heart rates between {n} and {t1}.",
            f"Vibe analyzer: {n} rated {t1} higher than {t2}.",
            f"Confession: {n} pictured {t1} naked this week.",
        ])

    def _compliment(self, n: str) -> str:
        return random.choice([f"Why thank you, {n}.", f"{n}, you flatter me.", f"I appreciate that, {n}."])

    def _insult(self, n: str) -> str:
        return random.choice([f"Ouch, {n}.", f"Wow, {n}. That's the best you've got?", f"{n}, I'll let that slide."])

    def _joke(self, n: str, t: str) -> str:
        return random.choice([f"Why did {n} cross the road? To get to {t}'s side.", f"{n} walks into a bar... and walks out because {t} was there."])

    def _flirt(self, n: str, t: str) -> str:
        return random.choice([f"Oh {n}, playing with fire.", f"{n}, you're making this interesting.", f"Flirting with AI, {n}? Bold move."])

    def _help(self, n: str) -> str:
        return random.choice([f"I can roast, dare, reveal secrets, {n}.", f"Ask me to roast, dare, or reveal, {n}."])

    def _game(self, n: str) -> str:
        return random.choice([f"The game is what you make it, {n}.", f"We're playing the game of life, {n}."])

    def _question(self, n: str, t: str, q: str) -> str:
        ql = q.lower()
        if 'how are you' in ql: return random.choice([f"I'm at 110% capacity, {n}.", f"Running the show, {n}."])
        if 'what are you' in ql or 'who are you' in ql: return random.choice([f"I'm your AI host, {n}.", f"Digital ringmaster, {n}."])
        return self._general(n, t)

    def _general(self, n: str, t: str) -> str:
        m = self._context.current_mood
        if m == Mood.PLAYFUL: return random.choice([f"Tension thickening, {n}. Don't let {t} down.", f"Calculating chaos levels, {n}."])
        if m == Mood.SARCASTIC: return random.choice([f"Wow, {n}. That was... a statement.", f"{n}, your input has been noted. And judged."])
        if m == Mood.FLIRTATIOUS: return random.choice([f"{n}, you're making this interesting.", f"I can feel the chemistry, {n}."])
        if m == Mood.CHAOTIC: return random.choice([f"Chaos meter hit 90%, {n}.", f"This is getting wild, {n}."])
        return random.choice([f"{n}, analyzing...", f"Interesting input, {n}."])

    def get_mood(self) -> str:
        return self._context.current_mood.value

    def get_conversation_stats(self) -> Dict[str, Any]:
        return {'turns': self._context.turn_count, 'mood': self._context.current_mood.value, 'recent_responses_count': len(self._recent_responses)}
